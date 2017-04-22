#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local WorkerManager = require 'packagemanager/WorkerManager'
local lanes = require 'lanes'


plan(1)

local function processor()
    local lanes = require 'lanes'

    return function( work )
        SetTaskProperty('work', 1337)
        while work > 0 do
            local chunk = math.min(work, 1)
            work = work - chunk
            lanes.sleep(chunk)
            SetTaskProperty('work', work)
        end
    end
end

local manager = WorkerManager{typeName = 'test',
                              processor = processor,
                              --[[minWorkerCount = 2,
                              maxWorkerCount = 4]]}
local tasks = {}
for i = 1, 5 do
    local task = manager:createTask({3})
    task:start()
    table.insert(tasks, task)
end

while true do
    lanes.sleep(0.5)
    manager:update()
    local runningTasks = 0
    --io.stdout:write('\r')
    for i, task in ipairs(tasks) do
        local work = task.properties.work
        print(type(work), work)
        --[[
        local status
        if work then
            status = string.format('% 1d', work)
        else
            status = '  '
        end
        io.stdout:write(tostring(i), ':', status, '  ')
        if task.status == 'running' then
            runningTasks = runningTasks + 1
        end
        ]]
    end
    io.stdout:write('\n')
    if runningTasks == 0 then
        --io.stdout:write('\n')
        break
    else
        --io.stdout:flush()
    end
end

manager:destroy()
ok(true, '')
