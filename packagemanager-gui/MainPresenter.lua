local PackageManager           = require 'packagemanager/init'
local xrc                      = require 'packagemanager-gui/xrc'
local utils                    = require 'packagemanager-gui/utils'
local Event                    = require 'packagemanager-gui/Event'
local MainView                 = require 'packagemanager-gui/MainView'
local UpdateTimer              = require 'packagemanager-gui/UpdateTimer'
local StatusBarPresenter       = require 'packagemanager-gui/StatusBarPresenter'
local PackageListPresenter     = require 'packagemanager-gui/PackageListPresenter'
local RequirementListPresenter = require 'packagemanager-gui/RequirementListPresenter'
local ChangeListPresenter      = require 'packagemanager-gui/ChangeListPresenter'
local RepositoryListPresenter  = require 'packagemanager-gui/RepositoryListPresenter'


local MainPresenter = {}
MainPresenter.__index = MainPresenter

function MainPresenter:updateRepositoryIndices()
    local tasks = PackageManager.updateRepositoryIndices()
    local function update()
        local completedTaskCount = 0
        for _, task in ipairs(tasks) do
            if task.status == 'complete' or
               task.status == 'failure' then
                completedTaskCount = completedTaskCount + 1
           end
        end
        self.statusBarPresenter:setMessage('indices',
                                           string.format('Downloading repository indices %d/%d ...',
                                                         completedTaskCount,
                                                         #tasks))
        if completedTaskCount == #tasks then
            self.updateTimer:requestMinFrequency(self, nil)
            self.statusBarPresenter:setMessage('indices', nil)
            PackageManager.buildPackageDB()
            self.packageDbUpdated()
        end
    end
    if #tasks > 0 then
        for _, task in ipairs(tasks) do
            task.events.started  = update
            task.events.fail     = update
            task.events.complete = update
        end
        update()
        self.updateTimer:requestMinFrequency(self, 1/20)
    else
        PackageManager.buildPackageDB()
        self.packageDbUpdated()
    end
end

function MainPresenter:destroy()
    self.statusBarPresenter:destroy()
    self.packageListPresenter:destroy()
    self.requirementListPresenter:destroy()
    self.changeListPresenter:destroy()
    self.repositoryListPresenter:destroy()
    self.updateTimer:destroy()
    self.view:destroy()
end

return function( view )
    local self = setmetatable({}, MainPresenter)
    self.view = view

    self.packageDbUpdated = Event()
    self.updateTimer = UpdateTimer(view.frame)

    self.statusBarPresenter       = StatusBarPresenter(view.statusBarView)
    self.requirementListPresenter = RequirementListPresenter(view.requirementListView)
    self.repositoryListPresenter  = RepositoryListPresenter(view.repositoryListView, self)
    self.packageListPresenter     = PackageListPresenter(view.packageListView,
                                                         self.requirementListPresenter,
                                                         self.packageDbUpdated,
                                                         view)
    self.changeListPresenter      = ChangeListPresenter(view.changeListView,
                                                        self.requirementListPresenter,
                                                        self.packageDbUpdated,
                                                        self.statusBarPresenter,
                                                        view,
                                                        self.updateTimer)

    self:updateRepositoryIndices()

    return self
end
