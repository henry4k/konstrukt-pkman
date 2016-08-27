local wx = require 'wx'


local utils = {}

function utils.updateWindow( window )
    -- Call this to force layout of the children anew, e.g. after having added
    -- a child to or removed a child (window, other sizer or space) from the
    -- sizer while keeping the current dimension.
    --
    window:Layout()

    -- Tell the sizer to resize the virtual size of the window to match the
    -- sizer's minimal size.
    --
    -- This will not alter the on screen size of the window, but may cause the
    -- addition/removal/alteration of scrollbars required to view the virtual
    -- area in windows which manage it.
    --
    window:FitInside()
end

function utils.scrollWindowToEnd( window )
    window:ScrollLines(9999) -- hack :D
end

local CastOverrides =
{
    wxGauge95 = 'wxGauge'
}

function utils.autoCast( object )
    local className = object:GetClassInfo():GetClassName()
    className = CastOverrides[className] or className
    return object:DynamicCast(className)
end

function utils.getOperatingSystem() -- Unix, Windows, Mac
    local platformInfo = wx.wxPlatformInfo.Get()
    return platformInfo:GetOperatingSystemFamilyName()
end

function utils.getUiSubsystem() -- gtk, msw, cocoa
    local platformInfo = wx.wxPlatformInfo.Get()
    return platformInfo:GetPortIdShortName()
end

return utils
