local wx = require 'wx'
local Event = require 'packagemanager-gui/event'
local Xrc   = require 'packagemanager-gui/xrc'


local ChangeListView = {}
ChangeListView.__index = ChangeListView

local ListGridColumns = 5

function ChangeListView:addInstallEntry( packageName, packageVersion )
    local icon = wx.wxStaticBitmap( self.listWindow, wx.wxID_ANY, wx.wxArtProvider.GetBitmap('download', wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    self.listGridSizer:Add( icon, 0, wx.wxALL, 5 )

    local packageName = wx.wxStaticText( self.listWindow, wx.wxID_ANY, packageName, wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    packageName:Wrap( -1 )
    self.listGridSizer:Add( packageName, 0, wx.wxALL, 5 )

    local packageVersion = wx.wxStaticText( self.listWindow, wx.wxID_ANY, packageVersion, wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    packageVersion:Wrap( -1 )
    self.listGridSizer:Add( packageVersion, 0, wx.wxALL, 5 )

    local progressBar = wx.wxGauge( self.listWindow, wx.wxID_ANY, 100, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxGA_HORIZONTAL )
    progressBar:SetValue( 0 )
    self.listGridSizer:Add( progressBar, 0, wx.wxALL + wx.wxEXPAND, 5 )

    local progressText = wx.wxStaticText( self.listWindow, wx.wxID_ANY, "0 / 0 MiB", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    progressText:Wrap( -1 )
    self.listGridSizer:Add( progressText, 0, wx.wxALL + wx.wxALIGN_RIGHT, 5 )

    local entry = {}
    entry.windows = { icon = icon,
                      packageName = packageName,
                      packageVersion = packageVersion,
                      progressBar = progressBar,
                      progressText = progressText }
    table.insert(self.entries, entry)
    return #self.entries
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

    self.rootWindow = rootWindow

    self.totalProgressGauge = Xrc.getWindow(self.rootWindow, 'totalProgressGauge')
    self.totalProgressText  = Xrc.getWindow(self.rootWindow, 'totalProgressText')

    self.applyButton = Xrc.getWindow(self.rootWindow, 'applyButton')
    self.applyButtonPressed = Event()
    self.applyButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function() self.applyButtonPressed() end)

    self.abortButton = Xrc.getWindow(self.rootWindow, 'abortButton')
    self.abortButtonPressed = Event()
    self.abortButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function() self.abortButtonPressed() end)

    self.listWindow = Xrc.getWindow(self.rootWindow, 'changeWindow')

    local listGridSizer = wx.wxFlexGridSizer( 0, ListGridColumns, 0, 0 )
    listGridSizer:AddGrowableCol( 3 )
    listGridSizer:SetFlexibleDirection( wx.wxHORIZONTAL )
    listGridSizer:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )
    self.listWindow:SetSizer( listGridSizer )

    -- update layout:
    self.listWindow:Layout()
    listGridSizer:Fit( self.listWindow )

    self.listGridSizer = listGridSizer

    self.entries = {}


    return self
end
