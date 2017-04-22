local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local xrc = require 'packagemanager-gui/xrc'


local function showError( message, level, parentWindow )
    level = level or 1

    local frame = xrc.createFrame('errorFrame', parentWindow)

    local messageText      = xrc.getWindow(frame, 'messageText')
    local reportText       = xrc.getWindow(frame, 'reportText')
    local showReportButton = xrc.getWindow(frame, 'showReportButton')
    local hideReportButton = xrc.getWindow(frame, 'hideReportButton')
    local copyReportButton = xrc.getWindow(frame, 'copyReportButton')
    local okButton         = xrc.getWindow(frame, 'wxID_OK')

    local function showReport( enabled )
        showReportButton:Show(not enabled)
        hideReportButton:Show(enabled)
        reportText:Show(enabled)
        utils.updateWindow(frame)
    end

    local report = debug.traceback(message, level+1)
    print(report)
--[[
    messageText:SetLabel(message)
    reportText:SetValue(report)

    showReportButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        frame:Freeze()
        showReport(true)
        frame:Thaw()
    end)
    hideReportButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        frame:Freeze()
        showReport(false)
        frame:Thaw()
    end)
    copyReportButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        utils.setClipboard(report)
    end)
    okButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        frame:Close(true)
    end)
    frame:Connect(wx.wxEVT_CLOSE_WINDOW, function( event )
        frame:MakeModal(false)
        frame:Destroy()
        event:Skip()
        os.exit(1) -- TODO
    end)

    frame:MakeModal(true)
    okButton:SetFocus()
    showReport(false)
    frame:ClearBackground()
    frame:Show()
    ]]
end

return showError
