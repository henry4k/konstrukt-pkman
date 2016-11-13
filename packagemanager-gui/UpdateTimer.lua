local wx             = require 'wx'
local PackageManager = require 'packagemanager/init'
local utils          = require 'packagemanager-gui/utils'
local Event          = require 'packagemanager-gui/Event'


local UpdateTimer = {}
UpdateTimer.__index = UpdateTimer

function UpdateTimer:_setFrequency( seconds )
    print('UpdateTimer set to '..tostring(seconds))
    if seconds then
        assert(seconds > 0)
        self.timer:Start(math.ceil(seconds*1000))
    else
        self.timer:Stop()
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
end

return function( window )
    local self = setmetatable({}, UpdateTimer)

    self.moduleFrequencies = {}

    self.updateEvent = Event()

    local timer = wx.wxTimer(window)
    self.timer = timer
    utils.connect(window, 'timer', function()
        PackageManager.update()
        self.updateEvent()
    end)

    return self
end
