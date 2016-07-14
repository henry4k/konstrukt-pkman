local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local Event = require 'packagemanager-gui/event'
local Xrc   = require 'packagemanager-gui/xrc'


local RequirementGroupsView = {}
RequirementGroupsView.__index = RequirementGroupsView

local RequirementGridSizerColumns = 5

function RequirementGroupsView:_createRequirementAddButton( groupName )
    local groupEntry = self.groupEntries[groupName]
    local gridSizer = groupEntry.windows.entryGridSizer
    local window = groupEntry.windows.window

    for _ = 1, RequirementGridSizerColumns-1 do
        gridSizer:Add(0, 0, 1, wx.wxEXPAND, 5)
    end

    local addButton = wx.wxBitmapButton( window, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_NEW, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    gridSizer:Add( addButton, 0, wx.wxALL, 5 )
    addButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        self.addRequirementEvent(groupName)
    end)
end

function RequirementGroupsView:addRequirementEntry( groupName, requirement )
    local groupEntry = self.groupEntries[groupName]
    local gridSizer = groupEntry.windows.entryGridSizer
    local window = groupEntry.windows.window

    local entry = {}

    local insertIndex = gridSizer:GetChildren():GetCount() - RequirementGridSizerColumns

    local packageName = wx.wxTextCtrl( window, wx.wxID_ANY, "Name", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    gridSizer:Insert(insertIndex, packageName, 0, wx.wxALL + wx.wxEXPAND, 5 )
    insertIndex = insertIndex + 1

    local searchPackageNameButton = wx.wxBitmapButton( window, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_FIND, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    gridSizer:Insert(insertIndex, searchPackageNameButton, 0, wx.wxALL, 5 )
    insertIndex = insertIndex + 1

    local separator = wx.wxStaticLine( window, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxLI_VERTICAL )
    gridSizer:Insert(insertIndex, separator, 0, wx.wxEXPAND + wx.wxALL, 5 )
    insertIndex = insertIndex + 1

    local versionRangeCtrl = wx.wxTextCtrl( window, wx.wxID_ANY, "Version range", wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    gridSizer:Insert(insertIndex, versionRangeCtrl, 0, wx.wxALL + wx.wxEXPAND, 5 )
    insertIndex = insertIndex + 1

    local removeButton = wx.wxBitmapButton( window, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_DELETE, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    gridSizer:Insert(insertIndex, removeButton, 0, wx.wxALL, 5 )
    insertIndex = insertIndex + 1

    removeButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        self.removeRequirementEvent(groupName, entry)
    end)

    entry.windows = { packageName = packageName,
                      searchPackageNameButton = searchPackageNameButton,
                      separator = separator,
                      versionRangeCtrl = versionRangeCtrl,
                      removeButton = removeButton }
    groupEntry.requirementEntries[entry] = entry
    return entry
end

function RequirementGroupsView:showRequirementEntry( groupName, entry )
    -- TODO Hack here
    local groupEntry = self.groupEntries[groupName]
    local window = groupEntry.windows.window
    utils.updateWindow(window)
    utils.scrollWindowToEnd(window)
end

function RequirementGroupsView:removeRequirementEntry( groupName, entry )
    local groupEntry = self.groupEntries[groupName]
    assert(groupEntry.requirementEntries[entry], 'Invalid entry.')
    for _, window in pairs(entry.windows) do
        groupEntry.windows.entryGridSizer:Detach(window)
        window:Destroy()
    end
    table.remove(groupEntry.requirementEntries, index)
    utils.updateWindow(groupEntry.windows.window)
end

function RequirementGroupsView:addGroupEntry( groupName )
    assert(not self.groupEntries[groupName], 'Group with this name already exists.')

    local window = wx.wxScrolledWindow( self.groupNotebook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxHSCROLL + wx.wxVSCROLL )
    window:SetScrollRate( 5, 5 )
    local mainSizer = wx.wxBoxSizer( wx.wxVERTICAL )

    local toolBarSizer = wx.wxBoxSizer( wx.wxHORIZONTAL )

    local nameTextCtrl = wx.wxTextCtrl( window, wx.wxID_ANY, groupName, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_PROCESS_ENTER )
    toolBarSizer:Add( nameTextCtrl, 1, wx.wxALL, 5 )
    nameTextCtrl:Connect(wx.wxEVT_KILL_FOCUS, function()
        self.renameGroupEvent(groupName, nameTextCtrl:GetValue())
    end)
    nameTextCtrl:Connect(wx.wxEVT_COMMAND_TEXT_ENTER, function()
        self.renameGroupEvent(groupName, nameTextCtrl:GetValue())
    end)
    nameTextCtrl:Connect(wx.wxEVT_COMMAND_TEXT_UPDATED, function()
        local pageIndex = assert(self:_getGroupEntryPageIndex(groupName))
        self.groupNotebook:SetPageText(pageIndex, nameTextCtrl:GetValue()..'*')
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

    self.groupNotebook:AddPage(window, groupName, false )


    local entry = { windows = { window = window,
                                mainSizer = mainSizer,
                                toolBarSizer = toolBarSizer,
                                nameTextCtrl = nameTextCtrl,
                                renameButton = renameButton,
                                createButton = createButton,
                                line = line,
                                entryGridSizer = entryGridSizer },
                    requirementEntries = {} }
    self.groupEntries[groupName] = entry

    self:_createRequirementAddButton(groupName)

    utils.updateWindow(window)
end

function RequirementGroupsView:renameGroupEntry( oldName, newName )
    if oldName == newName then
        return
    end

    local entry = assert(self.groupEntries[oldName], 'No such group.')
    assert(not self.groupEntries[newName], 'There is alrady a group with this name.')
    self.groupEntries[oldName] = nil
    self.groupEntries[newName] = entry

    local nameTextCtrl = entry.windows.nameTextCtrl
    if nameTextCtrl:GetValue() ~= newName then
        nameTextCtrl:ChangeValue(newName)
    end

    local pageIndex = self:_getGroupEntryPageIndex(newName)
    self.groupNotebook:SetPageText(pageIndex, newName)
end

function RequirementGroupsView:_getGroupEntryPageIndex( groupName )
    local searchedPage = assert(self.groupEntries[groupName]).windows.window
    local notebook = self.groupNotebook
    for i = 0, notebook:GetPageCount()-1 do
        local page = utils.autoCast(notebook:GetPage(i))
        if page == searchedPage then
            return i
        end
    end
end

function RequirementGroupsView:selectGroupEntry( groupName )
    local notebook = self.groupNotebook
    local pageIndex = assert(self:_getGroupEntryPageIndex(groupName))
    if notebook:GetSelection() ~= pageIndex then
        notebook:SetSelection(pageIndex)
    end
end

function RequirementGroupsView:removeGroupEntry( groupName )
    local entry = assert(self.groupEntries[groupName])
    local pageIndex = self:_getGroupEntryPageIndex(groupName)
    self.groupNotebook:RemovePage(pageIndex)
    entry.windows.window:Destroy()
    self.groupEntries[groupName] = nil
end

function RequirementGroupsView:freeze()
    self.rootWindow:Freeze()
end

function RequirementGroupsView:thaw()
    self.rootWindow:Thaw()
end

function RequirementGroupsView:destroy()
    -- TODO
end

return function( rootWindow )
    local self = setmetatable({}, RequirementGroupsView)

    self.createGroupEvent = Event()
    self.removeGroupEvent = Event() -- groupName
    self.renameGroupEvent = Event() -- oldName, newName
    self.addRequirementEvent = Event() -- groupName
    self.removeRequirementEvent = Event() -- groupName, index

    self.rootWindow = rootWindow
    self.groupNotebook = Xrc.getWindow(self.rootWindow, 'requirementsNotebook')
    self.groupEntries = {}

    return self
end
