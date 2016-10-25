local wx = require 'wx'


local utils = {}

function utils.getTopLevelWindow( window )
    if window:IsTopLevel() then
        return window
    else
        return utils.getTopLevelWindow(assert(window:GetParent()))
    end
end

function utils.wrapCallbackForWx( callback )
    assert(callback, 'Callback missing')
    return function( ... )
        local showError = require 'packagemanager-gui/showError'
        return select(2, xpcall(callback, showError, ...))
    end
end

function utils.connect( eventHandler, eventName, callback )
    local eventId = assert(wx['wxEVT_'..string.upper(eventName)], 'Unknown event type')
    eventHandler:Connect(eventId, utils.wrapCallbackForWx(callback))
end

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
    if window:IsTopLevel() then
        window:Fit()
    else
        window:FitInside()
    end
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

function utils.setClipboard( value )
    local c = wx.wxClipboard:Get()
    if c:Open() then
        c:SetData(wx.wxTextDataObject(value))
        c:Close()
    else
        error('Can\'t access clipboard.')
    end
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
