local Event = require 'packagemanager-gui/event'
local Xrc   = require 'packagemanager-gui/xrc'


local RequirementGroupsView = {}
RequirementGroupsView.__index = RequirementGroupsView

local RequirementGridSizerColumns = 4

function RequirementGroupsView:_addRequirementEntry( groupEntry, requirement )
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

function RequirementGroupsView:_removeRequirementEntry( groupEntry, index )
    local entry = assert(groupEntry[index], 'Invalid index.')
    for _, window in pairs(entry.windows) do
        groupEntry.windows.entryGridSizer:Detach(window)
        window:Destroy()
    end
    table.remove(groupEntry.requirementEntries, index)
end

function RequirementGroupsView:addGroupEntry( groupName, requirements )
    local window = wx.wxScrolledWindow( self.groupNotebook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxHSCROLL + wx.wxVSCROLL )
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

    self.groupNotebook:AddPage(window, groupName, False )

    local pageIndex = self.groupNotebook:GetPageCount() - 1

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
    table.insert(self.groupEntries, entry)

    for _, requirement in ipairs(requirements) do
        self:_addRequirementEntry(entry, requirement)
    end

    -- update layout:
    window:Layout()
    mainSizer:Fit( window )
end

function RequirementGroupsView:removeGroupEntry( index )
    local entry = assert(self.groupEntries[index], 'Invalid index.')
    self.groupNotebook:RemovePage(entry.pageIndex)
    entry.windows.window:Destroy()
    table.remove(self.groupEntries, index)
end

function RequirementGroupsView:destroy()
    -- TODO
end

return function( rootWindow )
    local self = setmetatable({}, RequirementGroupsView)

    self.rootWindow = rootWindow
    self.groupNotebook = Xrc.getWindow(self.rootWindow, 'requirementsNotebook')
    self.groupEntries = {}

    return self
end
