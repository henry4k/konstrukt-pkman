local Event                 = require 'packagemanager-gui/event'
local Xrc                   = require 'packagemanager-gui/xrc'
local ChangeListView        = require 'packagemanager-gui/changelistview'
local RequirementGroupsView = require 'packagemanager-gui/requirementgroupsview'


local MainFrameView = {}
MainFrameView.__index = MainFrameView

function MainFrameView:show()
    self.frame:Show()
end

function MainFrameView:destroy()
    self.changeListView:destroy()
    self.requirementGroupsView:destroy()
    self.frame:Destroy()
end

return function()
    local self = setmetatable({}, MainFrameView)

    self.frame = Xrc.createFrame('mainFrame')

    local changeRoot = Xrc.getWindow(self.frame, 'changesPanel')
    self.changeListView = ChangeListView(changeRoot)

    local requirementsRoot = Xrc.getWindow(self.frame, 'requirementsPanel')
    self.requirementGroupsView = RequirementGroupsView(requirementsRoot)

    return self
end