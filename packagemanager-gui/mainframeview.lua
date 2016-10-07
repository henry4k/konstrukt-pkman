local wx = require 'wx'
local Event                 = require 'packagemanager-gui/event'
local Xrc                   = require 'packagemanager-gui/xrc'
local ChangeListView        = require 'packagemanager-gui/changelistview'
local RequirementGroupsView = require 'packagemanager-gui/requirementgroupsview'
local SearchView            = require 'packagemanager-gui/searchview'
local StatusBarView         = require 'packagemanager-gui/statusbarview'


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

    local frame = Xrc.createFrame('mainFrame')
    --frame:SetAcceleratorTable(...)
    --frame:SetDropTarget(...)
    self.frame = frame

    local changeRoot = Xrc.getWindow(frame, 'changesPanel')
    self.changeListView = ChangeListView(changeRoot)

    local requirementsRoot = Xrc.getWindow(frame, 'requirementsPanel')
    self.requirementGroupsView = RequirementGroupsView(requirementsRoot)

    local searchRoot = Xrc.getWindow(frame, 'searchPanel')
    self.searchView = SearchView(searchRoot)

    local statusBar = Xrc.getWindow(frame, 'statusBar')
    self.statusBarView = StatusBarView(statusBar)

    return self
end
