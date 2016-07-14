local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local Event = require 'packagemanager-gui/event'
local Xrc   = require 'packagemanager-gui/xrc'


local ChangeListView = {}
ChangeListView.__index = ChangeListView

local ListGridColumns = 6

function ChangeListView:addInstallEntry( packageName, packageVersion )
    local defaultSizerFlags = wx.wxALL + wx.wxALIGN_CENTER_VERTICAL

    local icon = wx.wxStaticBitmap( self.listWindow, wx.wxID_ANY, wx.wxArtProvider.GetBitmap('download', wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    self.listGridSizer:Add( icon, 0, defaultSizerFlags, 5 )

    local packageNameText = wx.wxStaticText( self.listWindow, wx.wxID_ANY, packageName, wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    packageNameText:Wrap( -1 )
    self.listGridSizer:Add( packageNameText, 0, defaultSizerFlags, 5 )

    local packageVersionText = wx.wxStaticText( self.listWindow, wx.wxID_ANY, packageVersion, wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    packageVersionText:Wrap( -1 )
    self.listGridSizer:Add( packageVersionText, 0, defaultSizerFlags, 5 )

    local progressBar = wx.wxGauge( self.listWindow, wx.wxID_ANY, 100, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxGA_HORIZONTAL + wx.wxGA_SMOOTH )
    progressBar:SetValue( 0 )
    self.listGridSizer:Add( progressBar, 0, defaultSizerFlags + wx.wxEXPAND, 5 )

    local progressText = wx.wxStaticText( self.listWindow, wx.wxID_ANY, "0 / 0 MiB", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    progressText:Wrap( -1 )
    self.listGridSizer:Add( progressText, 0, defaultSizerFlags + wx.wxALIGN_RIGHT, 5 )

    local infoButton = wx.wxBitmapButton( self.listWindow, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_INFORMATION, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    self.listGridSizer:Add( infoButton, 0, defaultSizerFlags, 5 )
    infoButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        self.showUpgradeInfoEvent(packageName, packageVersion)
    end)

    local entry = {}
    entry.windows = { icon = icon,
                      packageNameText = packageNameText,
                      packageVersionText = packageVersionText,
                      progressBar = progressBar,
                      progressText = progressText,
                      infoButton = infoButton }
    table.insert(self.entries, entry)

    utils.updateWindow(self.listWindow)
end

function ChangeListView:removeEntry( index )
    local entry = assert(self.entries[index], 'Invalid index.')
    for _, window in pairs(entry.windows) do
        self.listGridSizer:Detach(window)
        window:Destroy()
    end
    table.remove(self.entries, index)
end

function ChangeListView:enableApplyButton( status )
    self.applyButton:Enable(status)
end

function ChangeListView:enableAbortButton( status )
    self.abortButton:Enable(status)
end

function ChangeListView:updateTotalProgress()
    -- TODO
    -- self.totalProgressGauge:SetRange(x)
    self.totalProgressGauge:SetValue(0)
    self.totalProgressText:SetValue('x / x MiB')
end

function ChangeListView:destroy()
    --  TODO
end

return function( rootWindow )
    local self = setmetatable({}, ChangeListView)

    self.applyButtonPressEvent = Event()
    self.abortButtonPressEvent = Event()
    self.showUpgradeInfoEvent = Event() -- packageName, packageVersion

    self.rootWindow = rootWindow

    self.totalProgressGauge = Xrc.getWindow(self.rootWindow, 'totalProgressGauge')
    self.totalProgressText  = Xrc.getWindow(self.rootWindow, 'totalProgressText')

    self.applyButton = Xrc.getWindow(self.rootWindow, 'applyButton')
    self.applyButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function() self.applyButtonPressEvent() end)

    self.abortButton = Xrc.getWindow(self.rootWindow, 'abortButton')
    self.abortButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function() self.abortButtonPressEvent() end)

    self.listWindow = Xrc.getWindow(self.rootWindow, 'changeWindow')

    local listGridSizer = wx.wxFlexGridSizer( 0, ListGridColumns, 0, 0 )
    listGridSizer:AddGrowableCol( 3 )
    listGridSizer:SetFlexibleDirection( wx.wxHORIZONTAL )
    listGridSizer:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )
    self.listWindow:SetSizer( listGridSizer )

    self.listWindow:Layout()
    self.totalProgressGauge:Layout()

    self.listGridSizer = listGridSizer

    self.entries = {}


    return self
end
