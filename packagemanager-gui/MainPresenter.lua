local PackageManager           = require 'packagemanager/init'
local xrc                      = require 'packagemanager-gui/xrc'
local utils                    = require 'packagemanager-gui/utils'
local Event                    = require 'packagemanager-gui/Event'
local MainView                 = require 'packagemanager-gui/MainView'
local Timer                    = require 'packagemanager-gui/Timer'
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
            self.statusBarPresenter:setMessage('indices', nil)
            PackageManager.buildPackageDB()
            self.packageDbUpdated()
        end
    end

    local function completeAndUpdate()
        self.updateTimer:removeUser()
        update()
    end

    local function failAndUpdate( task )
        self.updateTimer:removeUser()
        update()
        error(task.error, 0)
    end

    if #tasks > 0 then
        for _, task in ipairs(tasks) do
            self.updateTimer:addUser()
            task.events.downloadStarted = update
            task.events.complete        = completeAndUpdate
            task.events.fail            = failAndUpdate
            task:start()
        end
        update()
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

    Timer.defaultWindow = view.frame

    self.packageDbUpdated = Event()
    self.updateTimer = UpdateTimer()

    self.statusBarPresenter       = StatusBarPresenter(view.statusBarView)
    self.requirementListPresenter = RequirementListPresenter(view.requirementListView)
    self.repositoryListPresenter  = RepositoryListPresenter(view.repositoryListView, self)
    self.changeListPresenter      = ChangeListPresenter(view.changeListView,
                                                        self.requirementListPresenter,
                                                        self.packageDbUpdated,
                                                        self.statusBarPresenter,
                                                        view,
                                                        self.updateTimer)
    self.packageListPresenter     = PackageListPresenter(view.packageListView,
                                                         self.requirementListPresenter,
                                                         self.changeListPresenter,
                                                         self.packageDbUpdated,
                                                         view)

    self:updateRepositoryIndices()

    return self
end
