local wx = require 'wx'
local Event = require 'packagemanager-gui/event'
local Xrc   = require 'packagemanager-gui/xrc'


local RequirementGroupsView = {}
RequirementGroupsView.__index = RequirementGroupsView

local RequirementGridSizerColumns = 5

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

    local removeButton = wx.wxBitmapButton( window, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_DELETE, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    gridSizer:Add( removeButton, 0, wx.wxALL, 5 )

    local entry = {}
    entry.windows = { packageName = packageName,
                      searchPackageNameButton = searchPackageNameButton,
                      separator = separator,
                      versionRangeCtrl = versionRangeCtrl,
                      removeButton = removeButton }
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

function RequirementGroupsView:addGroupEntry( groupName )
    local pageIndex = self.groupNotebook:GetPageCount()

    local window = wx.wxScrolledWindow( self.groupNotebook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxHSCROLL + wx.wxVSCROLL )
    window:SetScrollRate( 5, 5 )
    local mainSizer = wx.wxBoxSizer( wx.wxVERTICAL )

    local toolBarSizer = wx.wxBoxSizer( wx.wxHORIZONTAL )

    local nameTextCtrl = wx.wxTextCtrl( window, wx.wxID_ANY, groupName, wx.wxDefaultPosition, wx.wxDefaultSize )
    toolBarSizer:Add( nameTextCtrl, 1, wx.wxALL, 5 )
    nameTextCtrl:Connect(wx.wxEVT_KILL_FOCUS, function()
        self.renameGroupEvent(groupName, nameTextCtrl:GetValue())
    end)
    nameTextCtrl:Connect(wx.wxEVT_COMMAND_TEXT_UPDATED, function()
        self.groupNotebook:SetPageText(pageIndex, nameTextCtrl:GetValue())
    end)

    toolBarSizer:Add( 0, 0, 1, wx.wxEXPAND, 5 )

    local deleteButton = wx.wxBitmapButton( window, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_DELETE, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    toolBarSizer:Add( deleteButton, 0, wx.wxALL, 5 )
    deleteButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        self.removeGroupEvent(groupName)
    end)

    local createButton = wx.wxBitmapButton( window, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_NEW, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    toolBarSizer:Add( createButton, 0, wx.wxALL, 5 )
    createButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        self.createGroupEvent()
    end)


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


    local entry = { groupName = groupName,
                    pageIndex = pageIndex,
                    windows = { window = window,
                                mainSizer = mainSizer,
                                toolBarSizer = toolBarSizer,
                                nameTextCtrl = nameTextCtrl,
                                renameButton = renameButton,
                                createButton = createButton,
                                line = line,
                                entryGridSizer = entryGridSizer },
                    requirementEntries = {} }
    self.groupEntries[groupName] = entry

    -- update layout:
    window:Layout()
    mainSizer:Fit( window )
end

function RequirementGroupsView:removeGroupEntry( groupName )
    local entry = assert(self.groupEntries[groupName], 'No such group.')
    self.groupNotebook:RemovePage(entry.pageIndex)
    entry.windows.window:Destroy()
    self.groupEntries[groupName] = nil
end

function RequirementGroupsView:destroy()
    -- TODO
end

return function( rootWindow )
    local self = setmetatable({}, RequirementGroupsView)

    self.createGroupEvent = Event()
    self.removeGroupEvent = Event() -- groupName
    self.removeRequirementEvent = Event() -- groupName, index
    self.addRequirementEvent = Event() -- groupName
    self.renameGroupEvent = Event() -- oldName, newName

    self.rootWindow = rootWindow
    self.groupNotebook = Xrc.getWindow(self.rootWindow, 'requirementsNotebook')
    self.groupEntries = {}

    return self
end
