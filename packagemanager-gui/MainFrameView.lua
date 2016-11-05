local wx              = require 'wx'
local xrc             = require 'packagemanager-gui/xrc'
local utils           = require 'packagemanager-gui/utils'
local Event           = require 'packagemanager-gui/Event'
local PackageListView = require 'packagemanager-gui/PackageListView'
local RequirementListView = require 'packagemanager-gui/RequirementListView'
local ChangeListView  = require 'packagemanager-gui/ChangeListView'
local StatusBarView   = require 'packagemanager-gui/StatusBarView'


local MainFrameView = {}
MainFrameView.__index = MainFrameView

function MainFrameView:show()
    self.frame:Show()
end

function MainFrameView:_addPage( page, view )
    self.pageViewsById[page:GetId()] = view
end

function MainFrameView:getCurrentPageView()
    local pageId = self.notebook:GetCurrentPage():GetId()
    return self.pageViewsById[pageId] -- can be nil
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

    self.pageViewsById = {}

    local packagesPanel = xrc.getWindow(frame, 'packagesPanel')
    self.packageListView = PackageListView(packagesPanel)
    self:_addPage(packagesPanel, self.packageListView)

    local requirementsPanel = xrc.getWindow(frame, 'requirementsPanel')
    self.requirementListView = RequirementListView(requirementsPanel)
    self:_addPage(requirementsPanel, self.requirementListView)

    local changesPanel = xrc.getWindow(frame, 'changesPanel')
    self.changeListView = ChangeListView(changesPanel)
    self:_addPage(changesPanel, self.changeListView)

    local statusBar = xrc.getWindow(frame, 'statusBar')
    self.statusBarView = StatusBarView(statusBar)

    self.pageChanged = Event()
    local notebook = xrc.getWindow(frame, 'notebook')
    self.notebook = notebook
    utils.connect(notebook, 'command_notebook_page_changed', function( e )
        self.pageChanged(self:getCurrentPageView())
    end)

    return self
end
