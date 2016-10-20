local wx = require 'wx'


local utils = {}

function utils.getTopLevelWindow( window )
    if window:IsTopLevel() then
        return window
    else
        return utils.getTopLevelWindow(assert(window:GetParent()))
    end
end

function utils.connect( eventHandler, eventName, callback )
    assert(callback, 'Callback missing')
    local eventId = assert(wx['wxEVT_'..string.upper(eventName)], 'Unknown event type')

    eventHandler:Connect(eventId, function( event )
        local showError = require 'packagemanager-gui/showError'
        xpcall(callback, showError, event)
    end)
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
    window:Fit()
    --window:FitInside()
end

function utils.scrollWindowToEnd( window )
    window:ScrollLines(9999) -- hack :D
end

function utils.addListColumn( list, items )
    --local item = wx.wxListItem()
    --for i, itemData in ipairs(items) do
    --    item:Clear()
    --    item:SetColumn(i-1) -- zero based index
    --    if itemData.data then
    --        item:SetData(itemData.data)
    --    end
    --    if itemData.image then
    --        item:SetImage(itemData.image)
    --    end
    --    if itemData.text then
    --        item:SetText(itemData.text)
    --    end
    --    list:InsertItem(item)
    --end
    --item:delete()

    local itemIndex = list:InsertItem(0, items[1].text or '', items[1].image or -1)
    for i = 2, #items do
        list:SetItem(itemIndex, i-1, items[i].text or '', items[i].image or -1)
    end
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
