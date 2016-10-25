local xrc             = require 'packagemanager-gui/xrc'
local PackageListView = require 'packagemanager-gui/PackageListView'
local RequirementListView = require 'packagemanager-gui/RequirementListView'
local ChangeListView  = require 'packagemanager-gui/ChangeListView'
local StatusBarView   = require 'packagemanager-gui/StatusBarView'


local MainFrameView = {}
MainFrameView.__index = MainFrameView

function MainFrameView:show()
    self.frame:Show()
end

function MainFrameView:destroy()
    self.packageListView:destroy()
    self.requirementListView:destroy()
    self.changeListView:destroy()
    self.statusBarView:destroy()
    self.frame:Destroy()
end

return function()
    local self = setmetatable({}, MainFrameView)

    local frame = xrc.createFrame('mainFrame')
    --frame:SetAcceleratorTable(...)
    --frame:SetDropTarget(...)
    self.frame = frame

    local packagesPanel = xrc.getWindow(frame, 'packagesPanel')
    self.packageListView = PackageListView(packagesPanel)

    local requirementsPanel = xrc.getWindow(frame, 'requirementsPanel')
    self.requirementListView = RequirementListView(requirementsPanel)

    local changesPanel = xrc.getWindow(frame, 'changesPanel')
    self.changeListView = ChangeListView(changesPanel)

    local statusBar = xrc.getWindow(frame, 'statusBar')
    self.statusBarView = StatusBarView(statusBar)

    return self
end
