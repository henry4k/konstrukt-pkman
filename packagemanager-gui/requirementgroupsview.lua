local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local Event = require 'packagemanager-gui/event'
local Xrc   = require 'packagemanager-gui/xrc'


local RequirementGroupsView = {}
RequirementGroupsView.__index = RequirementGroupsView

local RequirementGridSizerColumns = 5

function RequirementGroupsView:_createRequirementAddButton( group )
    assert(self.groups[group])
    local gridSizer = group.windows.requirementGridSizer
    local window = group.windows.window

    for _ = 1, RequirementGridSizerColumns-1 do
        gridSizer:Add(0, 0, 1, wx.wxEXPAND, 5)
    end

    local addButton = wx.wxBitmapButton( window, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_NEW, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    gridSizer:Add( addButton, 0, wx.wxALL, 5 )
    addButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        self.addRequirementEvent(group)
    end)
end

function RequirementGroupsView:addRequirement( group, unused )
    assert(self.groups[group])
    local gridSizer = group.windows.requirementGridSizer
    local window = group.windows.window

    local requirement = {}

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
        self.removeRequirementEvent(group, requirement)
    end)

    requirement.windows = { packageName = packageName,
                            searchPackageNameButton = searchPackageNameButton,
                            separator = separator,
                            versionRangeCtrl = versionRangeCtrl,
                            removeButton = removeButton }
    group.requirements[requirement] = requirement
    return requirement
end

function RequirementGroupsView:showRequirement( group, requirement )
    -- TODO Its a lie. It just scrolls to the bottom at the moment.
    assert(self.groups[group])
    local window = group.windows.window
    utils.updateWindow(window)
    utils.scrollWindowToEnd(window)
end

function RequirementGroupsView:removeRequirement( group, requirement )
    assert(self.groups[group])
    assert(group.requirements[requirement])
    for _, window in pairs(requirement.windows) do
        group.windows.requirementGridSizer:Detach(window)
        window:Destroy()
    end
    group.requirements[requirement] = nil
    utils.updateWindow(group.windows.window)
end

function RequirementGroupsView:getGroupByName( groupName )
    for _, group in pairs(self.groups) do
        if group.name == groupName then
            return group
        end
    end
end

function RequirementGroupsView:addGroup( groupName )
    assert(not self:getGroupByName(groupName), 'Group with this name already exists.')

    local group = {}
    group.name = groupName

    local window = wx.wxScrolledWindow( self.groupNotebook, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxHSCROLL + wx.wxVSCROLL )
    window:SetScrollRate( 5, 5 )
    local mainSizer = wx.wxBoxSizer( wx.wxVERTICAL )

    local toolBarSizer = wx.wxBoxSizer( wx.wxHORIZONTAL )

    local nameTextCtrl = wx.wxTextCtrl( window, wx.wxID_ANY, groupName, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTE_PROCESS_ENTER )
    toolBarSizer:Add( nameTextCtrl, 1, wx.wxALL, 5 )
    nameTextCtrl:Connect(wx.wxEVT_KILL_FOCUS, function()
        self.renameGroupEvent(group, nameTextCtrl:GetValue())
    end)
    nameTextCtrl:Connect(wx.wxEVT_COMMAND_TEXT_ENTER, function()
        self.renameGroupEvent(group, nameTextCtrl:GetValue())
    end)
    nameTextCtrl:Connect(wx.wxEVT_COMMAND_TEXT_UPDATED, function()
        local pageIndex = assert(self:_getGroupPageIndex(group))
        self.groupNotebook:SetPageText(pageIndex, nameTextCtrl:GetValue()..'*')
    end)

    toolBarSizer:Add( 0, 0, 1, wx.wxEXPAND, 5 )

    local deleteButton = wx.wxBitmapButton( window, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_DELETE, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    toolBarSizer:Add( deleteButton, 0, wx.wxALL, 5 )
    deleteButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        self.removeGroupEvent(group)
    end)

    local createButton = wx.wxBitmapButton( window, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_NEW, wx.wxART_MENU ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    toolBarSizer:Add( createButton, 0, wx.wxALL, 5 )
    createButton:Connect(wx.wxEVT_COMMAND_BUTTON_CLICKED, function()
        self.createGroupEvent()
    end)


    mainSizer:Add( toolBarSizer, 0, wx.wxEXPAND, 5 )

    local line = wx.wxStaticLine( window, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxLI_HORIZONTAL )
    mainSizer:Add( line, 0, wx.wxEXPAND  + wx. wxALL, 5 )

    local requirementGridSizer = wx.wxFlexGridSizer( 0, RequirementGridSizerColumns, 0, 0 )
    requirementGridSizer:AddGrowableCol( 0 )
    requirementGridSizer:AddGrowableCol( 3 )
    requirementGridSizer:SetFlexibleDirection( wx.wxBOTH )
    requirementGridSizer:SetNonFlexibleGrowMode( wx.wxFLEX_GROWMODE_SPECIFIED )


    mainSizer:Add( requirementGridSizer, 1, wx.wxEXPAND, 5 )

    window:SetSizer( mainSizer )

    self.groupNotebook:AddPage(window, groupName, false )


    group.windows = { window = window,
                      mainSizer = mainSizer,
                      toolBarSizer = toolBarSizer,
                      nameTextCtrl = nameTextCtrl,
                      renameButton = renameButton,
                      createButton = createButton,
                      line = line,
                      requirementGridSizer = requirementGridSizer }
    group.requirements = {}
    self.groups[group] = group

    self:_createRequirementAddButton(group)

    utils.updateWindow(window)

    return group
end

function RequirementGroupsView:renameGroup( group, newName )
    assert(self.groups[group])

    if group.name == newName then
        return
    end

    assert(not self:getGroupByName(newName), 'There is alrady a group with this name.')

    group.name = newName

    local nameTextCtrl = group.windows.nameTextCtrl
    if nameTextCtrl:GetValue() ~= newName then
        nameTextCtrl:ChangeValue(newName)
    end

    local pageIndex = self:_getGroupPageIndex(group)
    self.groupNotebook:SetPageText(pageIndex, newName)
end

function RequirementGroupsView:_getGroupPageIndex( group )
    assert(self.groups[group])
    local searchedPage = group.windows.window
    local notebook = self.groupNotebook
    for i = 0, notebook:GetPageCount()-1 do
        local page = utils.autoCast(notebook:GetPage(i))
        if page == searchedPage then
            return i
        end
    end
end

function RequirementGroupsView:selectGroup( group )
    assert(self.groups[group])
    local pageIndex = self:_getGroupPageIndex(group)
    local notebook = self.groupNotebook
    if notebook:GetSelection() ~= pageIndex then
        notebook:SetSelection(pageIndex)
    end
end

function RequirementGroupsView:removeGroup( group )
    assert(self.groups[group])
    local pageIndex = self:_getGroupPageIndex(group)
    self.groupNotebook:RemovePage(pageIndex)
    group.windows.window:Destroy()
    self.groups[group] = nil
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
    self.removeGroupEvent = Event() -- group
    self.renameGroupEvent = Event() -- group, newName
    self.addRequirementEvent = Event() -- group
    self.removeRequirementEvent = Event() -- group, requirement

    self.rootWindow = rootWindow
    self.groupNotebook = Xrc.getWindow(self.rootWindow, 'requirementsNotebook')
    self.groups = {}

    return self
end
