local xrc                      = require 'packagemanager-gui/xrc'
local utils                    = require 'packagemanager-gui/utils'
local MainView                 = require 'packagemanager-gui/MainView'
local UpdateTimer              = require 'packagemanager-gui/UpdateTimer'
local StatusBarPresenter       = require 'packagemanager-gui/StatusBarPresenter'
local PackageListPresenter     = require 'packagemanager-gui/PackageListPresenter'
local RequirementListPresenter = require 'packagemanager-gui/RequirementListPresenter'
local ChangeListPresenter      = require 'packagemanager-gui/ChangeListPresenter'


local MainPresenter = {}
MainPresenter.__index = MainPresenter

function MainPresenter:destroy()
    self.statusBarPresenter:destroy()
    self.packageListPresenter:destroy()
    self.requirementListPresenter:destroy()
    self.changeListPresenter:destroy()
    self.updateTimer:destroy()
    self.view:destroy()
end

return function( view )
    local self = setmetatable({}, MainPresenter)
    self.view = view

    self.updateTimer = UpdateTimer(view.frame)

    self.statusBarPresenter       = StatusBarPresenter(view.statusBarView)
    self.requirementListPresenter = RequirementListPresenter(view.requirementListView)
    self.packageListPresenter     = PackageListPresenter(view.packageListView,
                                                         self.requirementListPresenter,
                                                         view)
    self.changeListPresenter      = ChangeListPresenter(view.changeListView,
                                                        self.requirementListPresenter,
                                                        view,
                                                        self.updateTimer)

    return self
end
