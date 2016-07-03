local wx = require 'wx'
local Xrc = require 'packagemanager-gui/xrc'


local MainFrame = {}
local MainFrameMT = { __index = MainFrame }

local ChangeGridSizerColumns = 5
local RequirementGridSizerColumns = 4

function MainFrame:addChangeEntry( change )
    local icon = wx.wxStaticBitmap( self.changeWindow, wx.wxID_ANY, wx.wxArtProvider.GetBitmap('download', wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    self.changeGridSizer:Add( icon, 0, wx.wxALL, 5 )

    local packageName = wx.wxStaticText( self.changeWindow, wx.wxID_ANY, "base-game", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    packageName:Wrap( -1 )
    self.changeGridSizer:Add( packageName, 0, wx.wxALL, 5 )

    local packageVersion = wx.wxStaticText( self.changeWindow, wx.wxID_ANY, "0.1.0", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    packageVersion:Wrap( -1 )
    self.changeGridSizer:Add( packageVersion, 0, wx.wxALL, 5 )

    local progressBar = wx.wxGauge( self.changeWindow, wx.wxID_ANY, 100, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxGA_HORIZONTAL )
    progressBar:SetValue( 30 )
    self.changeGridSizer:Add( progressBar, 0, wx.wxALL + wx.wxEXPAND, 5 )

    local progressText = wx.wxStaticText( self.changeWindow, wx.wxID_ANY, "4 / 15 MiB", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    progressText:Wrap( -1 )
    self.changeGridSizer:Add( progressText, 0, wx.wxALL + wx.wxALIGN_RIGHT, 5 )

    local entry = {}
    entry.change = change
    entry.windows = { icon = icon,
                      packageName = packageName,
                      packageVersion = packageVersion,
                      progressBar = progressBar,
                      progressText = progressText }
    table.insert(self.changeEntries, entry)
end

function MainFrame:removeChangeEntry( index )
    local entry = assert(self.changeEntries[index], 'Invalid index.')
    for _, window in pairs(entry.windows) do
        self.changeGridSizer:Detach(window)
        window:Destroy()
    end
    table.remove(self.changeEntries, index)
end

function MainFrame:_addRequirementEntry( groupEntry, requirement )
    local gridSizer = groupEntry.gridSizer
    local panel = groupEntry.panel

    local packageName = wx.wxTextCtrl( panel, wx.wxID_ANY, "Name", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    gridSizer:Add( packageName, 0, wx.wxALL + wx.wxEXPAND, 5 )

    local searchPackageNameButton = wx.wxBitmapButton( panel, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_FIND, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    gridSizer:Add( searchPackageNameButton, 0, wx.wxALL, 5 )

    local separator = wx.wxStaticLine( panel, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxLI_VERTICAL )
    gridSizer:Add( separator, 0, wx.wxEXPAND + wx.wxALL, 5 )

    local versionRangeCtrl = wx.wxTextCtrl( panel, wx.wxID_ANY, "Version range", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    versionRangeCtrl:SetBackgroundColour( wx.wxSystemSettings.GetColour( wx.wxSYS_COLOUR_WINDOW ) )
    gridSizer:Add( versionRangeCtrl, 0, wx.wxALL + wx.wxEXPAND, 5 )

    local entry = {}
    entry.windows = { packageName = packageName,
                      searchPackageNameButton = searchPackageNameButton,
                      separator = separator,
                      versionRangeCtrl = versionRangeCtrl }
    table.insert(groupEntry.requirementEntries, entry)
end

function MainFrame:_removeRequirementEntry( groupEntry, index )
    local entry = assert(groupEntry[index], 'Invalid index.')
    for _, window in pairs(entry.windows) do
        groupEntry.gridSizer:Detach(window)
        window:Destroy()
    end
    table.remove(groupEntry.requirementEntries, index)
end

function MainFrame:addRequirementGroupEntry( groupName, requirements )
    local scrolledWindow = wx.wxScrolledWindow( self.requirementsListBook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxHSCROLL + wx.wxVSCROLL )
    scrolledWindow:SetScrollRate( 5, 5 )
    local sizer = wx.wxBoxSizer( wx.wxVERTICAL )

    local panel = wx.wxPanel( scrolledWindow, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTAB_TRAVERSAL )
    local gridSizer = wx.wxFlexGridSizer( 0, RequirementGridSizerColumns, 0, 0 )
    gridSizer:AddGrowableCol( 0 )
    gridSizer:SetFlexibleDirection( wx.wxHORIZONTAL )
    gridSizer:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )

    panel:SetSizer( gridSizer )
    panel:Layout()
    gridSizer:Fit( panel )
    sizer:Add( panel, 0, wx.wxEXPAND, 5 )

    local addRequirementButton = wx.wxBitmapButton( scrolledWindow, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_NEW, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    sizer:Add( addRequirementButton, 0, wx.wxALL, 5 )

    scrolledWindow:SetSizer( sizer )
    scrolledWindow:Layout()
    sizer:Fit( scrolledWindow )
    self.requirementsListBook:AddPage( scrolledWindow, groupName, False )

    local pageIndex = self.requirementsListBook:GetPageCount() - 1

    local entry = { groupName = groupName,
                    pageIndex = pageIndex,
                    scrolledWindow = scrolledWindow,
                    sizer = sizer,
                    panel = panel,
                    gridSizer = gridSizer,
                    addRequirementButton = addRequirementButton,
                    requirementEntries = {} }
    table.insert(self.requirementGroupEntries, entry)
    for _, requirement in ipairs(requirements) do
        self:_addRequirementEntry(entry, requirement)
    end
end

function MainFrame:removeRequirementGroupEntry( index )
    local entry = assert(self.requirementGroupEntries[index], 'Invalid index.')
    self.requirementsListBook:RemovePage(entry.pageIndex)
    entry.scrolledWindow:Destroy()
    table.remove(self.requirementGroupEntries, index)
end

return function()
    local self = setmetatable({}, MainFrameMT)

    self.frame = Xrc.createFrame('mainFrame')
    self.changeWindow = Xrc.getWindow(self.frame, 'changeWindow')

    local changeGridSizer = wx.wxFlexGridSizer( 0, ChangeGridSizerColumns, 0, 0 )
    changeGridSizer:AddGrowableCol( 3 )
    changeGridSizer:SetFlexibleDirection( wx.wxHORIZONTAL )
    changeGridSizer:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )
    self.changeWindow:SetSizer( changeGridSizer )
    self.changeWindow:Layout()
    changeGridSizer:Fit( self.changeWindow )
    self.changeGridSizer = changeGridSizer

    self.changeEntries = {}

    self.requirementsListBook = Xrc.getWindow(self.frame, 'requirementsListBook')
    self.requirementGroupEntries = {}

    return self
end
