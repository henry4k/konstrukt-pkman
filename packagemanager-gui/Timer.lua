local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'


local TimerStatic = { defaultWindow = nil }
setmetatable(TimerStatic, TimerStatic)

local Timer = {}
Timer.__index = Timer

function Timer:start( frequency, triggerOnce )
    assert(self.timer:Start(math.ceil(frequency*1000), triggerOnce or false))
    self.running = true
end

function Timer:startOnce( frequency )
    self:start(frequency, true)
end

function Timer:stop()
    self.timer:Stop()
    self.running = false
end

function Timer:destroy()
    self.timer = nil
end

function TimerStatic:__call( callback, window )
    window = window or TimerStatic.defaultWindow
    assert(window, 'Window has neither been passed nor there is a defaultWindow.')

    local self = setmetatable({}, Timer)
    self.id = utils.generateUniqueId()
    self.timer = wx.wxTimer(window, self.id)
    self.running = false
    self.callback = callback

    utils.connect(window, 'timer', function( e )
        assert(e:GetId() == self.id)
        self.callback(self)
    end, self.id)

    return self
end

return TimerStatic
