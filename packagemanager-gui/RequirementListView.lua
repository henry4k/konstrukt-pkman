local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local xrc   = require 'packagemanager-gui/xrc'
local Event = require 'packagemanager-gui/Event'


local RequirementListView = {}
RequirementListView.__index = RequirementListView

local ResultGridColumns = 3

function RequirementListView:getQuery()
    return self.searchCtrl:GetValue()
end

function RequirementListView:setQuery( query )
    self.searchCtrl:ChangeValue(query)
end

function RequirementListView:freeze()
    self.rootWindow:Freeze()
end

function RequirementListView:thaw()
    utils.updateWindow(self.rootWindow)
    self.rootWindow:Thaw()
end

function RequirementListView:destroy()
end

function RequirementListView:clear()
    local resultGrid = self.resultGrid
    for _, requirement in pairs(self.requirements) do
        self:removeRequirement(requirement)
    end
end

function RequirementListView:addRequirement( name, versionRange )
    local resultGrid = self.resultGrid
    local resultWindow = self.resultWindow

    local requirement = {}

    local insertIndex = resultGrid:GetChildren():GetCount() - ResultGridColumns

    local packageName = wx.wxTextCtrl( resultWindow, wx.wxID_ANY, name, wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    resultGrid:Insert(insertIndex, packageName, 0, wx.wxALL + wx.wxEXPAND, 5 )
    insertIndex = insertIndex + 1

    local versionRangeCtrl = wx.wxTextCtrl( resultWindow, wx.wxID_ANY, versionRange, wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    resultGrid:Insert(insertIndex, versionRangeCtrl, 0, wx.wxALL + wx.wxEXPAND, 5 )
    insertIndex = insertIndex + 1

    local removeButton = wx.wxBitmapButton( resultWindow, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_DELETE, wx.wxART_BUTTON ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    resultGrid:Insert(insertIndex, removeButton, 0, wx.wxALL, 5 )
    insertIndex = insertIndex + 1

    utils.connect(removeButton, 'command_button_clicked', function()
        self.removeRequirementEvent(requirement)
    end)

    requirement.windows = { packageName = packageName,
                            versionRangeCtrl = versionRangeCtrl,
                            removeButton = removeButton }
    self.requirements[requirement] = requirement
    return requirement
end

function RequirementListView:showRequirement( requirement )
    -- TODO Its a lie. It just scrolls to the bottom at the moment.
    utils.updateWindow(self.resultWindow)
    utils.scrollWindowToEnd(self.resultWindow)
end

function RequirementListView:removeRequirement( requirement )
    assert(self.requirements[requirement])
    local resultGrid = self.resultGrid
    for _, window in pairs(requirement.windows) do
        resultGrid:Detach(window)
        window:Destroy()
    end
    self.requirements[requirement] = nil
    utils.updateWindow(self.resultWindow)
end

return function( rootWindow )
    local self = setmetatable({}, RequirementListView)

    self.requirements = {}

    self.searchChangeEvent = Event()
    self.addRequirementEvent = Event()
    self.removeRequirementEvent = Event()

    self.rootWindow = rootWindow

    local searchCtrl = xrc.getWindow(rootWindow, 'searchCtrl')
    self.searchCtrl = searchCtrl
    utils.connect(searchCtrl, 'command_text_updated', self.searchChangeEvent)

    local resultWindow = xrc.getWindow(rootWindow, 'resultWindow')
    self.resultWindow = resultWindow

    self.resultGrid = resultWindow:GetSizer()

    local addRequirementButton = xrc.getWindow(rootWindow, 'addRequirementButton')
    utils.connect(addRequirementButton, 'command_button_clicked', self.addRequirementEvent)

    return self
end
