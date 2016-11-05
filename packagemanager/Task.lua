local misc = require 'packagemanager/misc'
local unpack = unpack or table.unpack -- backward compatibility to 5.1


local Task = {}
Task.__index = Task

--- Signal successful completion with the given result value.
-- Used by the owner.
function Task:complete( result )
    assert(self.status == 'running')
    self.status = 'complete'
    self.result = result
    self:fireEvent('complete')
end

--- Signal failure with the given error object.
-- Used by the owner.
function Task:fail( error )
    assert(self.status == 'running')
    self.status = 'failure'
    self.error = error
    self:fireEvent('fail')
end

function Task:fireEvent( name, ... )
    local fn = self.events[name]
    if fn then
        fn(self, ...)
        return true
    else
        return false
    end
end

local function ResumeCoroutineAndPropagateErrors( coro, ... )
    local returnValues = {coroutine.resume(coro, ...)}
    local success = returnValues[1]
    if not success then
        error(returnValues[2], 0)
    else
        return unpack(returnValues, 2)
    end
end

--- Suspend a running coroutine until the task is completed or failed.
--This overrides the completion and failure event handlers.
--
--@return
--On successful completion it returns `true` and the tasks result. 
--On failure it returns `false` and the error object.
function Task:wait()
    print('at the beginning of Task:wait() self = '..tostring(self))
    if self.status == 'running' then
        local coro = coroutine.running()
        local function resumeFn( task )
            ResumeCoroutineAndPropagateErrors(coro)
        end
        self.events.complete = resumeFn
        self.events.fail     = resumeFn
        coroutine.yield()
    end

    if self.status == 'complete' then
        return true, self.result
    elseif self.status == 'failure' then
        return false, self.error
    else
        error('Unexpected status '..self.status)
    end
end

local ReadOnlyMT = { __newindex = function() error('Properties cannot be changed.') end }

local function DefaultCompletionHandler( task )
end

local function DefaultFailureHandler( task )
    error(task.error, 0)
end

local function CreateTask( events )
    local self = setmetatable({}, Task)
    self.status = 'running'
    events = misc.copyTable(events or {})
    events.complete = events.complete or DefaultCompletionHandler
    events.fail     = events.fail     or DefaultFailureHandler
    self.events = events
    return self
end

local function CreateTaskFromFunction( fn, ... )
    local task = CreateTask()
    local function wrapperFn(...)
        local success, resultOrErr = xpcall(fn, debug.traceback, ...)
        if success then
            task:complete(resultOrErr)
        else
            task:fail(resultOrErr)
        end
    end
    local coro = coroutine.create(wrapperFn)
    ResumeCoroutineAndPropagateErrors(coro, task, ...)
    return task
end

return setmetatable({ fromFunction = CreateTaskFromFunction },
                    { __call = CreateTask })

