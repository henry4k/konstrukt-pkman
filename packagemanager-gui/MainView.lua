local wx                  = require 'wx'
local xrc                 = require 'packagemanager-gui/xrc'
local utils               = require 'packagemanager-gui/utils'
local Event               = require 'packagemanager-gui/Event'
local StatusBarView       = require 'packagemanager-gui/StatusBarView'
local PackageListView     = require 'packagemanager-gui/PackageListView'
local RequirementListView = require 'packagemanager-gui/RequirementListView'
local ChangeListView      = require 'packagemanager-gui/ChangeListView'
local RepositoryListView  = require 'packagemanager-gui/RepositoryListView'


local MainView = {}
MainView.__index = MainView

function MainView:show()
    self.frame:Show()
end

function MainView:_addPage( page, view )
    self.pageViewsById[page:GetId()] = view
end

function MainView:getCurrentPageView()
    local pageId = self.notebook:GetCurrentPage():GetId()
    return self.pageViewsById[pageId] -- can be nil
end

function MainView:destroy()
    self.statusBarView:destroy()
    self.packageListView:destroy()
    self.requirementListView:destroy()
    self.changeListView:destroy()
    self.repositoryListView:destroy()
    self.frame:Destroy()
end

return function()
    local self = setmetatable({}, MainView)

    local frame = xrc.createFrame('mainFrame')
    self.frame = frame

    self.pageViewsById = {}

    local statusBar = xrc.getWindow(frame, 'statusBar')
    self.statusBarView = StatusBarView(statusBar)

    local packagesPanel = xrc.getWindow(frame, 'packagesPanel')
    self.packageListView = PackageListView(packagesPanel)
    self:_addPage(packagesPanel, self.packageListView)

    local requirementsPanel = xrc.getWindow(frame, 'requirementsPanel')
    self.requirementListView = RequirementListView(requirementsPanel)
    self:_addPage(requirementsPanel, self.requirementListView)

    local changesPanel = xrc.getWindow(frame, 'changesPanel')
    self.changeListView = ChangeListView(changesPanel)
    self:_addPage(changesPanel, self.changeListView)

    local repositoryPanel = xrc.getWindow(frame, 'repositoryPanel')
    self.repositoryListView = RepositoryListView(repositoryPanel)

    self.pageChanged = Event()
    local notebook = xrc.getWindow(frame, 'notebook')
    self.notebook = notebook
    utils.connect(notebook, 'command_notebook_page_changed', function( e )
        self.pageChanged(self:getCurrentPageView())
    end)

    return self
end
