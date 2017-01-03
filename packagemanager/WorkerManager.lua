local lanes = require('lanes').configure{ with_timers = false,
                                          verbose_errors = true }
local unpack = unpack or table.unpack -- backward compatibility to 5.1
local Task = require 'packagemanager/Task'


local Manager = {}
local ManagerMT = { __index = Manager }

local function WorkerFn( ThreadName, TaskQueueLinda, TaskLinda, Processor )
    local unpack = _G.unpack or table.unpack -- backward compatibility to 5.1

    set_debug_threadname(ThreadName)

    local ProcessorCb = Processor()

    local function EmitEvent( e )
        TaskLinda:send('events', e)
    end

    function EmitTaskEvent( fnName, ... )
        EmitEvent{ type = 'call', fnName = fnName, arguments = {...} }
    end

    local UsedProperties = {}

    function SetTaskProperty( name, value )
        TaskLinda:set(name, value)
        UsedProperties[name] = true
    end

    local function CollectProperties()
        local properties = {}
        for name, _ in pairs(UsedProperties) do
            local value = TaskLinda:get(name)
            if value ~= lanes.cancel_error then
                properties[name] = value
            end
        end
        return properties
    end

    local function ClearProperties()
        for name, _ in pairs(UsedProperties) do
            TaskLinda:set(name, nil)
            UsedProperties[name] = nil
        end
    end

    -- Use Linda to receive Tasks from Queue
    while true do
        ClearProperties()
        local result, taskQueueEntry = TaskQueueLinda:receive('tasks')
        if result == lanes.cancel_error then
            break
        end
        local taskId    = taskQueueEntry.id
        local arguments = taskQueueEntry.arguments
        EmitEvent{ type = 'start task', taskId = taskId }

        local success, result = pcall(ProcessorCb, unpack(arguments))
        local properties = CollectProperties()
        if success then
            EmitEvent{ type = 'finish task',
                       status = 'complete',
                       properties = properties,
                       result = result }
        else
            EmitEvent{ type = 'finish task',
                       status = 'fail',
                       properties = properties,
                       errMsg = result }
        end
    end

    return 'ok'
end
local DefaultWorkerCount = 1

---
-- @param typeName
-- @param processor
-- @param[optional] workerCount
-- @param[optional] laneLibraries
-- @param[optional] laneOptions
local function CreateManager( options )
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
        tasks = {},
        nextTaskId = 1001
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
        task = nil
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
            if not worker.task then
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

function Manager:_getTaskById( id )
    for _, task in ipairs(self.tasks) do
        if task.id == id then
            return task
        end
    end
end

local function boundBy( v, min, max )
    return math.min(math.max(v, min), max)
end

function Manager:_adaptWorkerCount()
    local oldWorkerCount = #self.workers
    local newWorkerCount = boundBy(#self.tasks,
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
        local value = thread[1] -- the value will never be assigned
    end
end

local function HandleWorkerEvent( manager, worker, event )
    if event.type == 'start task' then
        assert(not worker.task)
        local task = assert(manager:_getTaskById(event.taskId))
        assert(not task.worker, 'Task is already being worked on.')
        worker.task = task
        task.worker = worker
        --task.status = 'running'
        --task:fireEvent('start')
    elseif event.type == 'finish task' then
        local task = assert(worker.task)
        -- remove task from table:
        for i, task in ipairs(manager.tasks) do
            if task == worker.task then
                table.remove(manager.tasks, i)
            end
        end
        task.worker = nil
        task.properties = event.properties
        worker.task = nil
        manager:_adaptWorkerCount()
        if event.status == 'complete' then
            task:complete(event.result)
        elseif event.status == 'fail' then
            task:fail(event.errMsg)
        else
            error('Unknown status '..event.status)
        end
    elseif event.type == 'call' then
        local fnName    = event.fnName
        local arguments = event.arguments
        local task = assert(worker.task)
        task:fireEvent(fnName, unpack(arguments))
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

function Manager:_genTaskId()
    local id = self.nextTaskId
    self.nextTaskId = id + 1
    return id
end

local function GetTaskProperty( worker, name )
    local value = worker.cachedProperties[name]
    if not value then
        value = worker.linda:get(name)
        worker.cachedProperties[name] = value
    end
    return value
end

local TaskPropertiesMT = {}

function TaskPropertiesMT:__index( key )
    local worker = self._task.worker
    if worker then
        return GetTaskProperty(worker, key)
    end
end

function TaskPropertiesMT:__newindex()
    error('Properties can not be changed.')
end

local function OnWorkerTaskStart( task, startParameter )
    local manager = startParameter.workerManager
    manager:_adaptWorkerCount()

    local taskQueueEntry =
    {
        id = task.id,
        arguments = startParameter.arguments
    }
    manager.masterLinda:send('tasks', taskQueueEntry)
end

function Manager:createTask( arguments )
    local task = Task()
    task.id = self:_genTaskId()
    task.properties = setmetatable({ _task = task }, TaskPropertiesMT)

    table.insert(self.tasks, task)

    task.startParameter = { workerManager = self,
                            arguments = arguments }
    task.events.start = OnWorkerTaskStart

    return task
end

return CreateManager
