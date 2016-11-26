local PackageManager = require 'packagemanager/init'
local Event          = require 'packagemanager-gui/Event'
local Timer          = require 'packagemanager-gui/Timer'


local UpdateTimer = {}
UpdateTimer.__index = UpdateTimer

function UpdateTimer:_update()
    if self.userCount > 0 then
        self.timer:start(self.frequency)
    else
        self.timer:stop()
    end
end

function UpdateTimer:setFrequency( seconds )
    assert(seconds > 0, 'Seconds must be a positive number.')
    self.frequency = seconds
    self:_update()
end

function UpdateTimer:addUser()
    self.userCount = self.userCount + 1
    self:_update()
end

function UpdateTimer:removeUser()
    self.userCount = self.userCount - 1
    self:_update()
end

function UpdateTimer:destroy()
    self.timer:destroy()
end

return function( window )
    local self = setmetatable({}, UpdateTimer)

    self.frequency = 1/20
    self.userCount = 0
    self.updateEvent = Event()

    local function callback()
        PackageManager.update()
        self.updateEvent()
    end
    self.timer = Timer(callback, window)

    return self
end
