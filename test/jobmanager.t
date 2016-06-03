#!/usr/bin/env lua
-- vim: set filetype=lua:
require 'Test.More'
local JobManager = require 'packagemanager/jobmanager'
local lanes = require 'lanes'


plan(1)

local function processor()
    local lanes = require 'lanes'

    return function( work )
        while work > 0 do
            local chunk = math.min(work, 1)
            work = work - chunk
            lanes.sleep(chunk)
            SetJobProperty('work', work)
        end
    end
end

local manager = JobManager.create{typeName = 'test', processor = processor, workerCount = 2}
local jobs = {}
for i = 1, 5 do
    local job = manager:createJob({3}, {})
    table.insert(jobs, job)
end

while true do
    lanes.sleep(1)
    manager:update()
    local runningJobs = 0
    --io.stdout:write('\r')
    for i, job in ipairs(jobs) do
        local work = job.properties.work
        local status
        if work then
            status = string.format('% 1d', work)
        else
            status = '  '
        end
        io.stdout:write(tostring(i), ':', status, '  ')
        if job.status == 'running' then
            runningJobs = runningJobs + 1
        end
    end
    io.stdout:write('\n')
    if runningJobs == 0 then
        --io.stdout:write('\n')
        break
    else
        --io.stdout:flush()
    end
end

manager:destroy()
ok(true, '')
