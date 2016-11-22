local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local Event = require 'packagemanager-gui/Event'
local xrc   = require 'packagemanager-gui/xrc'


local ChangeListView = {}
ChangeListView.__index = ChangeListView

local ListGridColumns = 6

function ChangeListView:addChange( changeType,
                                   packageName,
                                   packageVersion )
    local change = {}
    change.type = changeType

    local iconName = 'package-'..changeType

    local defaultSizerFlags = wx.wxALL + wx.wxALIGN_CENTER_VERTICAL

    local icon = wx.wxStaticBitmap( self.listWindow, wx.wxID_ANY, wx.wxArtProvider.GetBitmap(iconName, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    self.listGridSizer:Add( icon, 0, defaultSizerFlags, 5 )

    local packageNameText = wx.wxStaticText( self.listWindow, wx.wxID_ANY, packageName, wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    packageNameText:Wrap( -1 )
    self.listGridSizer:Add( packageNameText, 0, defaultSizerFlags, 5 )

    local packageVersionText = wx.wxStaticText( self.listWindow, wx.wxID_ANY, packageVersion, wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    packageVersionText:Wrap( -1 )
    self.listGridSizer:Add( packageVersionText, 0, defaultSizerFlags, 5 )

    local progressBar
    local progressText
    local infoButton
    if changeType == 'install' then
        progressBar = wx.wxGauge( self.listWindow, wx.wxID_ANY, 1, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxGA_HORIZONTAL + wx.wxGA_SMOOTH )
        self.listGridSizer:Add( progressBar, 0, defaultSizerFlags + wx.wxEXPAND, 5 )

        progressText = wx.wxStaticText( self.listWindow, wx.wxID_ANY, "", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
        progressText:Wrap( -1 )
        self.listGridSizer:Add( progressText, 0, defaultSizerFlags + wx.wxALIGN_RIGHT, 5 )

        infoButton = wx.wxBitmapButton( self.listWindow, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_INFORMATION, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
        self.listGridSizer:Add( infoButton, 0, defaultSizerFlags, 5 )
        utils.connect(infoButton, 'command_button_clicked', function()
            self.showUpgradeInfoEvent(packageName, packageVersion)
        end)
    else
        -- add placeholders
        for i = 1, 3 do
            self.listGridSizer:Add(0, 0, 1, defaultSizerFlags, 5)
        end
    end

    change.windows = { icon = icon,
                       packageNameText = packageNameText,
                       packageVersionText = packageVersionText,
                       progressBar = progressBar,
                       progressText = progressText,
                       infoButton = infoButton }
    self.changes[change] = change

    utils.updateWindow(self.listWindow)

    return change
end

function ChangeListView:setChangeTotalBytes( change, totalBytes )
    change.totalBytes = totalBytes
    if totalBytes then
        change.windows.progressBar:SetRange(totalBytes)
    end
    self:updateChangeBytesWritten(change, change.bytesWritten or 0)
    self:_updateTotalBytes()
end


function ChangeListView:updateChangeBytesWritten( change, bytesWritten )
    local totalBytes = change.totalBytes
    if bytesWritten ~= change.bytesWritten then
        change.bytesWritten = bytesWritten
        if totalBytes then
            change.windows.progressBar:SetValue(bytesWritten)
        else
            change.windows.progressBar:Pulse()
        end
        change.windows.progressText:SetLabel(utils.buildProgressString(bytesWritten, totalBytes))
    end
    self.listWindow:Layout()
    self:_updateBytesWritten()
end

function ChangeListView:markChangeAsCompleted( change )
    if not change.totalBytes then
        local bytesWritten = change.bytesWritten
        local progressBar = change.windows.progressBar
        progressBar:SetRange(bytesWritten)
        progressBar:SetValue(bytesWritten)
    end
end

function ChangeListView:removeChange( change )
    assert(self.changes[change])
    for _, window in pairs(change.windows) do
        self.listGridSizer:Detach(window)
        window:Destroy()
    end
    self.changes[change] = nil
end

function ChangeListView:clearChanges()
    for change in pairs(self.changes) do
        self:removeChange(change)
    end

    self.totalProgressGauge:SetValue(0)
    self.totalProgressText:SetLabel('')
    self.totalProgressWindow:Layout()

    self.statusBarPresenter:setMessage('changes', nil) -- Its a hack. See constructor of ChangeListPresenter.
end

function ChangeListView:enableButton( name )
    if name == 'apply' then
        self.applyButton:Enable(true)
        self.cancelButton:Enable(false)
        self.completeButton:Enable(false)
    elseif name == 'cancel' then
        self.applyButton:Enable(false)
        self.cancelButton:Enable(true)
        self.completeButton:Enable(false)
    elseif name == 'complete' then
        self.applyButton:Enable(false)
        self.cancelButton:Enable(false)
        self.completeButton:Enable(true)
    elseif name == nil then
        self.applyButton:Enable(false)
        self.cancelButton:Enable(false)
        self.completeButton:Enable(false)
    else
        error('Unknown button '..name)
    end
end

function ChangeListView:_updateTotalBytes()
    local totalBytes = 0
    for change in pairs(self.changes) do
        if change.totalBytes then
            totalBytes = totalBytes + change.totalBytes
        else
            totalBytes = nil
            break
        end
    end

    if totalBytes then
        self.totalProgressGauge:SetRange(totalBytes)
    end

    self._totalBytes = totalBytes

    self:_updateBytesWritten()
end

function ChangeListView:_calcBytesWritten()
    local bytesWritten = 0
    for change in pairs(self.changes) do
        bytesWritten = bytesWritten + (change.bytesWritten or 0)
    end
    return bytesWritten
end

function ChangeListView:_updateBytesWritten()
    local bytesWritten = self:_calcBytesWritten()

    local totalBytes = self._totalBytes
    if totalBytes then
        self.totalProgressGauge:SetValue(bytesWritten)
    else
        self.totalProgressGauge:Pulse()
    end
    self.totalProgressText:SetLabel(utils.buildProgressString(bytesWritten, totalBytes))

    self.totalProgressWindow:Layout()


    local message = string.format('Downloaded %s packages ...',
                                  utils.buildProgressString(bytesWritten, totalBytes))
    self.statusBarPresenter:setMessage('changes', message) -- Its a hack. See constructor of ChangeListPresenter.
end

function ChangeListView:markAsCompleted()
    if not self._totalBytes then
        local bytesWritten = self:_calcBytesWritten()
        self.totalProgressGauge:SetRange(bytesWritten)
        self.totalProgressGauge:SetValue(bytesWritten)
    end
end

function ChangeListView:freeze()
    self.rootWindow:Freeze()
end

function ChangeListView:thaw()
    self.rootWindow:Thaw()
end

function ChangeListView:destroy()
    -- TODO
end

return function( rootWindow )
    local self = setmetatable({}, ChangeListView)

    self.applyButtonPressEvent    = Event()
    self.cancelButtonPressEvent   = Event()
    self.completeButtonPressEvent = Event()
    self.showUpgradeInfoEvent     = Event() -- packageName, packageVersion

    self.rootWindow = rootWindow

    self.totalProgressWindow = xrc.getWindow(self.rootWindow, 'totalProgressWindow')
    self.totalProgressGauge  = xrc.getWindow(self.rootWindow, 'totalProgressGauge')
    self.totalProgressText   = xrc.getWindow(self.rootWindow, 'totalProgressText')

    self.applyButton = xrc.getWindow(self.rootWindow, 'wxID_APPLY')
    utils.connect(self.applyButton, 'command_button_clicked', self.applyButtonPressEvent)

    self.cancelButton = xrc.getWindow(self.rootWindow, 'wxID_CANCEL')
    utils.connect(self.cancelButton, 'command_button_clicked', self.cancelButtonPressEvent)

    self.completeButton = xrc.getWindow(self.rootWindow, 'wxID_OK')
    utils.connect(self.completeButton, 'command_button_clicked', self.completeButtonPressEvent)

    self.listWindow = xrc.getWindow(self.rootWindow, 'changeWindow')

    local listGridSizer = wx.wxFlexGridSizer( 0, ListGridColumns, 0, 0 )
    listGridSizer:AddGrowableCol( 3 )
    listGridSizer:SetFlexibleDirection( wx.wxHORIZONTAL )
    listGridSizer:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )
    self.listWindow:SetSizer( listGridSizer )

    self.listWindow:Layout()
    self.totalProgressGauge:Layout()

    self.listGridSizer = listGridSizer

    self.changes = {}

    return self
end
