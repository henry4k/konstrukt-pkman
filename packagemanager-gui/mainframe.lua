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
    local gridSizer = groupEntry.windows.entryGridSizer
    local window = groupEntry.windows.window

    local packageName = wx.wxTextCtrl( window, wx.wxID_ANY, "Name", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    gridSizer:Add( packageName, 0, wx.wxALL + wx.wxEXPAND, 5 )

    local searchPackageNameButton = wx.wxBitmapButton( window, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_FIND, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    gridSizer:Add( searchPackageNameButton, 0, wx.wxALL, 5 )

    local separator = wx.wxStaticLine( window, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxLI_VERTICAL )
    gridSizer:Add( separator, 0, wx.wxEXPAND + wx.wxALL, 5 )

    local versionRangeCtrl = wx.wxTextCtrl( window, wx.wxID_ANY, "Version range", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
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
        groupEntry.windows.entryGridSizer:Detach(window)
        window:Destroy()
    end
    table.remove(groupEntry.requirementEntries, index)
end

function MainFrame:addRequirementGroupEntry( groupName, requirements )
    local window = wx.wxScrolledWindow( self.requirementsNotebook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxHSCROLL + wx.wxVSCROLL )
    window:SetScrollRate( 5, 5 )
    local mainSizer = wx.wxBoxSizer( wx.wxVERTICAL )

    local toolBarSizer = wx.wxBoxSizer( wx.wxHORIZONTAL )

    local nameTextCtrl = wx.wxTextCtrl( window, wx.wxID_ANY, groupName, wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    toolBarSizer:Add( nameTextCtrl, 1, wx.wxALL, 5 )

    local renameButton = wx.wxBitmapButton( window, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_REDO, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    toolBarSizer:Add( renameButton, 0, wx.wxALL, 5 )


    toolBarSizer:Add( 0, 0, 1, wx.wxEXPAND, 5 )

    local deleteButton = wx.wxBitmapButton( window, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_DELETE, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    toolBarSizer:Add( deleteButton, 0, wx.wxALL, 5 )

    local createButton = wx.wxBitmapButton( window, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_NEW, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    toolBarSizer:Add( createButton, 0, wx.wxALL, 5 )


    mainSizer:Add( toolBarSizer, 0, wx.wxEXPAND, 5 )

    local line = wx.wxStaticLine( window, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxLI_HORIZONTAL )
    mainSizer:Add( line, 0, wx.wxEXPAND  + wx. wxALL, 5 )

    local entryGridSizer = wx.wxFlexGridSizer( 0, RequirementGridSizerColumns, 0, 0 )
    entryGridSizer:AddGrowableCol( 0 )
    entryGridSizer:AddGrowableCol( 3 )
    entryGridSizer:SetFlexibleDirection( wx.wxBOTH )
    entryGridSizer:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )


    mainSizer:Add( entryGridSizer, 1, wx.wxEXPAND, 5 )


    window:SetSizer( mainSizer )
    window:Layout()
    mainSizer:Fit( window )
    self.requirementsNotebook:AddPage(window, groupName, False )

    local pageIndex = self.requirementsNotebook:GetPageCount() - 1

    local entry = { groupName = groupName,
                    pageIndex = pageIndex,
                    windows = { window = window,
                                mainSizer = mainSizer,
                                toolBarSizer = toolBarSizer,
                                nameTextCtrl = nameTextCtrl,
                                renameButton = renameButton,
                                deleteButton = deleteButton,
                                createButton = createButton,
                                line = line,
                                entryGridSizer = entryGridSizer },
                    requirementEntries = {} }
    table.insert(self.requirementGroupEntries, entry)
    for _, requirement in ipairs(requirements) do
        self:_addRequirementEntry(entry, requirement)
    end
end

function MainFrame:removeRequirementGroupEntry( index )
    local entry = assert(self.requirementGroupEntries[index], 'Invalid index.')
    self.requirementsNotebook:RemovePage(entry.pageIndex)
    entry.windows.window:Destroy()
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

    self.requirementsNotebook = Xrc.getWindow(self.frame, 'requirementsNotebook')
    self.requirementGroupEntries = {}

    return self
end
