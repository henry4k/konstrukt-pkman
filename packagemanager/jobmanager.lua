local lanes = require('lanes').configure{ with_timers = false,
                                          verbose_errors = true }
local unpack = unpack or table.unpack -- backward compatibility to 5.1


local JobManager = {}

local Manager = {}
local ManagerMT = { __index = Manager }

local function WorkerFn( ThreadName, JobQueueLinda, JobLinda, Processor )
    local unpack = _G.unpack or table.unpack -- backward compatibility to 5.1

    set_debug_threadname(ThreadName)

    local ProcessorCb = Processor()

    local function EmitEvent( e )
        JobLinda:send('events', e)
    end

    function EmitJobEvent( fnName, ... )
        EmitEvent{ type = 'call', fnName = fnName, arguments = {...} }
    end

    local UsedProperties = {}

    function SetJobProperty( name, value )
        JobLinda:set(name, value)
        UsedProperties[name] = true
    end

    local function CollectProperties()
        local properties = {}
        for name, _ in pairs(UsedProperties) do
            local value = JobLinda:get(name)
            if value ~= lanes.cancel_error then
                properties[name] = value
            end
        end
        return properties
    end

    local function ClearProperties()
        for name, _ in pairs(UsedProperties) do
            JobLinda:set(name, nil)
            UsedProperties[name] = nil
        end
    end

    -- Use Linda to receive Jobs from Queue
    while true do
        ClearProperties()
        local result, jobQueueEntry = JobQueueLinda:receive('jobs')
        if result == lanes.cancel_error then
            break
        end
        local jobId     = jobQueueEntry.id
        local arguments = jobQueueEntry.arguments
        EmitEvent{ type = 'start job', jobId = jobId }

        local success, result = pcall(ProcessorCb, unpack(arguments))
        local properties = CollectProperties()
        if success then
            EmitEvent{ type = 'finish job',
                       status = 'success',
                       properties = properties,
                       result = result }
        else
            EmitEvent{ type = 'finish job',
                       status = 'fail',
                       properties = properties,
                       errMsg = result }
        end
    end
end
local DefaultWorkerCount = 1

---
-- @param typeName
-- @param processor
-- @param[optional] workerCount
-- @param[optional] laneLibraries
-- @param[optional] laneOptions
function JobManager.create( options )
    local typeName  = assert(options.typeName, 'typeName missing')
    local processor = assert(options.processor, 'processor missing')
    local minWorkerCount = options.minWorkerCount or 0
    local maxWorkerCount = options.maxWorkerCount or 1
    local laneLibraries = options.laneLibraries or '*'
    local laneOptions   = options.laneOptions or {}

    assert(minWorkerCount <= maxWorkerCount, 'minWorkerCount must be smaller or equal to maxWorkerCount')

    local masterLinda = lanes.linda(typeName..' manager')
    local workerGenerator = lanes.gen(laneLibraries, laneOptions, WorkerFn)

    local instance =
    {
        typeName = typeName,
        minWorkerCount = minWorkerCount,
        maxWorkerCount = maxWorkerCount,
        processor = processor,
        masterLinda = masterLinda, -- communication between master and worker
        workerGenerator = workerGenerator,
        workers = {},
        jobs = {},
        nextJobId = 1001
    }
    setmetatable(instance, ManagerMT)

    instance:_adaptWorkerCount()

    return instance
end

function ManagerMT:__tostring()
    return self.typeName..' manager'
end

function Manager:destroy()
    self:_stopAllWorkersNow()
end

function Manager:_startWorker()
    local workerName = self.typeName..' worker'
    local linda = lanes.linda(string.format('%s worker', self.typeName))
    local thread = self.workerGenerator(workerName, self.masterLinda, linda, self.processor)
    local worker =
    {
        linda = linda,
        thread = thread,
        cachedProperties = {},
        job = nil
    }
    table.insert(self.workers, worker)
    return worker, #self.workers
end

function Manager:_stopAllWorkersNow()
    for _, worker in ipairs(self.workers) do
        worker.thread:cancel(-1, true)
    end

    for _, worker in ipairs(self.workers) do
        local __ = worker.thread[1] -- join and propagate error if one occurs
    end

    self.workers = {}
end

local function TryFindIdleWorkersIndex( manager )
    if #manager.workers > 0 then
        for i, worker in ipairs(manager.workers) do
            if not worker.job then
                return i
            end
        end
        return #manager.workers -- return last worker
    end
end

function Manager:_stopAWorker()
    local index = assert(TryFindIdleWorkersIndex(self))
    local worker = table.remove(self.workers, index)
    worker.thread:cancel(-1, true)
end

function Manager:_getJobById( id )
    for _, job in ipairs(self.jobs) do
        if job.id == id then
            return job
        end
    end
end

local function boundBy( v, min, max )
    return math.min(math.max(v, min), max)
end

function Manager:_adaptWorkerCount()
    local oldWorkerCount = #self.workers
    local newWorkerCount = boundBy(#self.jobs,
                                   self.minWorkerCount,
                                   self.maxWorkerCount)
    if newWorkerCount > oldWorkerCount then
        for i = 1, newWorkerCount-oldWorkerCount do
            self:_startWorker()
        end
    else
        for i = 1, oldWorkerCount-newWorkerCount do
            self:_stopAWorker()
        end
    end
end

local function HandleThreadError( manager, worker )
    local thread = worker.thread
    if thread.status == 'error' then
        local _, err = thread:join()
        error(string.format('Error in %s worker: %s', manager.typeName, err))
    end
end

local function HandleJobEvent( worker, name, ... )
    local job = assert(worker.job)
    local fn = job.eventHandler[name]
    if fn then
        fn(job, ...)
    end
end


local function HandleWorkerEvent( manager, worker, event )
    if event.type == 'start job' then
        assert(not worker.job)
        local job = assert(manager:_getJobById(event.jobId))
        assert(not job.worker, 'Job is already being worked on.')
        worker.job = job
        job.worker = worker
        job.status = 'running'
        HandleJobEvent(worker, 'start')
    elseif event.type == 'finish job' then
        assert(worker.job)
        -- remove job from table:
        for i, job in ipairs(manager.jobs) do
            if job == worker.job then
                table.remove(manager.jobs, i)
            end
        end
        worker.job.worker = nil
        worker.job.status = 'finished'
        worker.job.properties = event.properties
        HandleJobEvent(worker, 'finish', worker.job.result, worker.job.errMsg)
        worker.job = nil
        manager:_adaptWorkerCount()
    elseif event.type == 'call' then
        local fnName    = event.fnName
        local arguments = event.arguments
        HandleJobEvent(worker, fnName, unpack(arguments))
    else
        error('Received unknown event from worker: '..event.type)
    end
end

local function HandleWorkerEvents( manager, worker )
    local linda = worker.linda
    local eventCount = linda:count('events') or 0
    if eventCount >= 1 then
        local events = {linda:receive(nil, linda.batched, 'events', eventCount)}
        -- events = key, value, value, ... (till eventCount)
        table.remove(events, 1) -- remove key
        for _, event in ipairs(events) do
            HandleWorkerEvent(manager, worker, event)
        end
    end
end

function Manager:update()
    for _, worker in ipairs(self.workers) do
        HandleThreadError(self, worker)
        HandleWorkerEvents(self, worker)
        worker.cachedProperties = {}
    end
end

local function GetJobProperty( worker, name )
    local value = worker.cachedProperties[name]
    if not value then
        value = worker.linda:get(name)
        worker.cachedProperties[name] = value
    end
    return value
end

function Manager:_genNextJobId()
    local id = self.nextJobId
    self.nextJobId = id + 1
    return id
end

local Job = {}
local JobMT = { __index = Job }
local JobPropertiesMT = {}

function JobPropertiesMT:__index( key )
    local worker = self._job.worker
    if worker then
        return GetJobProperty(worker, key)
    end
end

function JobPropertiesMT:__newindex()
    error('Properties can not be changed.')
end

function Manager:createJob( arguments, eventHandler )
    local instance =
    {
        typeName = self.typeName,
        id = self:_genNextJobId(),
        eventHandler = eventHandler or {},
        status = 'waiting'
    }
    setmetatable(instance, JobMT)
    table.insert(self.jobs, instance)

    self:_adaptWorkerCount()

    local jobQueueEntry =
    {
        id = instance.id,
        arguments = arguments
    }
    self.masterLinda:send('jobs', jobQueueEntry)

    instance.properties = setmetatable({ _job = instance }, JobPropertiesMT)

    return instance
end

function JobMT:__tostring()
    return self.typeName
end


return JobManager
