local PackageManager = require 'packagemanager/init'
local Event          = require 'packagemanager-gui/Event'
local Timer          = require 'packagemanager-gui/Timer'


local UpdateTimer = {}
UpdateTimer.__index = UpdateTimer

function UpdateTimer:_setFrequency( seconds )
    if seconds then
        assert(seconds > 0)
        self.timer:start(seconds)
    else
        self.timer:stop()
    end
end

function UpdateTimer:requestMinFrequency( module, seconds )
    self.moduleFrequencies[module] = seconds
    local minSeconds
    for _, seconds in pairs(self.moduleFrequencies) do
        if not minSeconds then
            minSeconds = seconds
        else
            minSeconds = math.min(minSeconds, seconds)
        end
    end
    self:_setFrequency(minSeconds)
end

function UpdateTimer:destroy()
    self.timer:destroy()
end

return function( window )
    local self = setmetatable({}, UpdateTimer)

    self.moduleFrequencies = {}
    self.updateEvent = Event()

    local function callback()
        PackageManager.update()
        self.updateEvent()
    end
    self.timer = Timer(callback, window)

    return self
end
