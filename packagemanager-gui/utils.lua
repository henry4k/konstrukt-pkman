local wx = require 'wx'
local Unit = require 'packagemanager/unit'


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

function utils.connect( eventHandler, eventName, callback, id )
    local eventId = assert(wx['wxEVT_'..string.upper(eventName)], 'Unknown event type')
    local wrappedCallback = utils.wrapCallbackForWx(callback)
    if id then
        eventHandler:Connect(id, eventId, wrappedCallback)
    else
        eventHandler:Connect(eventId, wrappedCallback)
    end
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

function utils.buildProgressString( bytesWritten, totalBytes )
    if totalBytes then
        local unit = Unit.get('bytes', totalBytes)
        return string.format('%.1f / %.1f %s', bytesWritten/unit.size, totalBytes/unit.size, unit.symbol)
    else
        local unit = Unit.get('bytes', bytesWritten)
        return string.format('%.1f %s', bytesWritten/unit.size, unit.symbol)
    end
end

local nextId = 1
function utils.generateUniqueId()
    local id = nextId
    nextId = nextId + 1
    return id
end

return utils
