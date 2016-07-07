local Event = require 'packagemanager-gui/event'
local Xrc   = require 'packagemanager-gui/xrc'


local ChangeListView = {}
ChangeListView.__index = ChangeListView

local ListGridColumns = 5

function ChangeListView:addEntry( change )
    local icon = wx.wxStaticBitmap( self.listWindow, wx.wxID_ANY, wx.wxArtProvider.GetBitmap('download', wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    self.listGridSizer:Add( icon, 0, wx.wxALL, 5 )

    local packageName = wx.wxStaticText( self.listWindow, wx.wxID_ANY, "base-game", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    packageName:Wrap( -1 )
    self.listGridSizer:Add( packageName, 0, wx.wxALL, 5 )

    local packageVersion = wx.wxStaticText( self.listWindow, wx.wxID_ANY, "0.1.0", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    packageVersion:Wrap( -1 )
    self.listGridSizer:Add( packageVersion, 0, wx.wxALL, 5 )

    local progressBar = wx.wxGauge( self.listWindow, wx.wxID_ANY, 100, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxGA_HORIZONTAL )
    progressBar:SetValue( 30 )
    self.listGridSizer:Add( progressBar, 0, wx.wxALL + wx.wxEXPAND, 5 )

    local progressText = wx.wxStaticText( self.listWindow, wx.wxID_ANY, "4 / 15 MiB", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    progressText:Wrap( -1 )
    self.listGridSizer:Add( progressText, 0, wx.wxALL + wx.wxALIGN_RIGHT, 5 )

    local entry = {}
    entry.change = change
    entry.windows = { icon = icon,
                      packageName = packageName,
                      packageVersion = packageVersion,
                      progressBar = progressBar,
                      progressText = progressText }
    table.insert(self.entries, entry)
end

function ChangeListView:removeEntry( index )
    local entry = assert(self.entries[index], 'Invalid index.')
    for _, window in pairs(entry.windows) do
        self.listGridSizer:Detach(window)
        window:Destroy()
    end
    table.remove(self.entries, index)
end

function ChangeListView:destroy()
    --  TODO
end

return function( rootWindow )
    local self = setmetatable({}, ChangeListView)


    self.rootWindow = rootWindow
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
