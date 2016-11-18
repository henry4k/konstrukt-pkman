local wx = require 'wx'


local StatusBarView = {}
StatusBarView.__index = StatusBarView

function StatusBarView:setText( text )
    self.window:SetStatusText(text, 0)
end

function StatusBarView:freeze()
    self.window:Freeze()
end

function StatusBarView:thaw()
    self.window:Thaw()
end

function StatusBarView:destroy()
end

return function( window )
    local self = setmetatable({}, StatusBarView)
    self.window = window
    window:SetFieldsCount(1)
    return self
end
