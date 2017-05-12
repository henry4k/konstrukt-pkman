local PackageManager = require 'packagemanager/init'
local Misc = require 'packagemanager/misc'
local Unit = require 'packagemanager/unit'
local lanes = require 'packagemanager/lanes'
local Bar = require 'packagemanager-cli/bar'
local RateCalculator = require 'packagemanager-cli/RateCalculator'
local RichText = require 'packagemanager-cli/RichText'
local Output = require 'packagemanager-cli/output'


local RenderBar
local BarPrefix
local BarPostfix
if Output.features.unicode then
    RenderBar = Bar.renderUnicodeBar
    BarPrefix = RichText('▕')..Output.attributes('underline', 'overline')
    BarPostfix = Output.attributes('reset')..'▏'
else
    RenderBar = Bar.renderSimpleBar
    BarPrefix = '['
    BarPostfix = ']'
end

---
-- @tparam width
-- @tparam totalBytes
-- @tparam bytesWritten
-- @tparam rate
-- @tparam eta
local function RenderStatus( t )
    local totalBytes = t.totalBytes
    local bytesWritten = t.bytesWritten
    local rate = t.rate
    local eta = t.eta or 0 -- TODO

    local completion = bytesWritten / totalBytes
    local bytesLeft = totalBytes - bytesWritten
    local byteUnit = Unit.get('bytes', bytesLeft)
    local rateUnit = Unit.get('bytes', rate)
    local etaUnit  = Unit.get('seconds', eta)

    local prefix = RichText(BarPrefix)
    local postfix = RichText.merge(BarPostfix,
                                   ' ',
                                   string.format('%2d', completion*100),
                                   '% ',
                                   Output.attributes('yellow', 'underline'),
                                   byteUnit:formatStatic(bytesLeft, '-'),
                                   Output.attributes('reset'),
                                   ' ',
                                   Output.attributes('magenta', 'underline'),
                                   etaUnit:formatStatic(eta, '~'),
                                   Output.attributes('reset'),
                                   ' ',
                                   Output.attributes('cyan', 'underline'),
                                   rateUnit:formatStatic(rate, nil, '/s'),
                                   Output.attributes('reset'))
    local barWidth = t.width - #prefix - #postfix
    local bar = RichText(RenderBar(barWidth, completion), barWidth)
    return prefix..bar..postfix
end

local function GetDownloadStatistics( changeTasks )
    local totalBytes = 0
    local bytesWritten = 0
    for change, task in pairs(changeTasks) do
        totalBytes = totalBytes + change.package.size
        local downloadTask = task.downloadTask
        if downloadTask then
            bytesWritten = bytesWritten + (downloadTask.properties.bytesWritten or 0)
        end
    end
    return totalBytes, bytesWritten
end

local function TasksAreRunningOrQueued( tasks )
    for _, task in pairs(tasks) do
        if task.status == 'unstarted' or
           task.status == 'running' then
           return true
       end
    end
    return false
end

local function ProcessChangeTasks( changeTasks )
    for change, task in pairs(changeTasks) do
        task.events.complete = function()
            local postfix = 'completed'
            if Output.features.unicode then
                postfix = '✅'
            end
            Output.log(RichText.merge(Output.attributes('green'),
                                      change.package.name,
                                      ' ',
                                      change.package.version,
                                      ' ',
                                      postfix,
                                      Output.attributes('reset')))
        end
        task.events.fail = function()
            Output.logError(task.error)
        end
        task:start()
    end

    local animation = Output.rewriteLine

    local updateRate
    if animation then
        updateRate = 1/5
    else
        updateRate = 1
    end

    local rateCalculator
    if animation then
        rateCalculator =
            RateCalculator(GetDownloadStatistics(changeTasks), -- totalBytes
                           updateRate,
                           0.95)
    end

    while true do
        PackageManager.update()
        if animation then
            local totalBytes, bytesWritten = GetDownloadStatistics(changeTasks)
            rateCalculator.totalAmount = totalBytes
            rateCalculator:update(bytesWritten)
            Output.stream:flush()
            Output.rewriteLine(RenderStatus{width = Output.features.maxLineLength,
                                            totalBytes = totalBytes,
                                            bytesWritten = bytesWritten,
                                            rate = rateCalculator:getAverageRate(),
                                            eta  = rateCalculator.eta})
            Output.stream:flush()
        end
        if TasksAreRunningOrQueued(changeTasks) then
            lanes.sleep(updateRate)
        else
            break
        end
    end
end

return { processChangeTasks = ProcessChangeTasks }
