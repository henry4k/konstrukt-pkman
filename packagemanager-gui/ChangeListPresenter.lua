local statemachine = require 'statemachine'
local bind = require('packagemanager/misc').bind
local PackageManager = require 'packagemanager/init'
local xrc = require 'packagemanager-gui/xrc'


local HighUpdateFrequency = 1/20
local LowUpdateFrequency  = 1

local ChangeListPresenter = {}
ChangeListPresenter.__index = ChangeListPresenter

function ChangeListPresenter:resetOrGatherChanges()
    self.state:reset()
    local changes = PackageManager.gatherChanges()
    if next(changes) then
        self.state:gatheredChanges(changes)
    end
end

local function AllTasksAreComplete( tasks )
    for _, task in pairs(tasks) do
        if task.status ~= 'complete' then
            return false
        end
    end
    return true
end

function ChangeListPresenter:updateUpdateFrequency()
    local frequency
    if self.state:is('applying') then
        if self.mainFrameView:getCurrentPageView() == self.view then
            frequency = HighUpdateFrequency
        else
            frequency = LowUpdateFrequency
        end
    else
        frequency = nil
    end
    self.updateTimer:requestMinFrequency(self, frequency)
end

function ChangeListPresenter:updateProgress()
    local view = self.view
    local changeHandleMap = self.changeHandleMap
    for change, task in pairs(self.changeTaskMap) do
        local viewHandle = assert(changeHandleMap[change])
        local downloadTask = task.downloadTask
        if downloadTask then
            local properties = downloadTask.properties
            local bytesWritten = properties.bytesWritten
            if bytesWritten then
                view:updateChangeBytesWritten(viewHandle, bytesWritten)
            end
        end
    end
    self.statusBarPresenter:setMessage('changes', string.format('... TODO ...'))
end

function ChangeListPresenter:destroy()
end

function ChangeListPresenter:_onEmpty()
    local view = self.view
    view:enableButton(nil)
    view:clearChanges()
end

function ChangeListPresenter:_onReady( changes )
    local view = self.view

    view:enableButton('apply')

    local handleMap = {}
    for _, change in ipairs(changes) do
        local handle = view:addChange(change.type, change.package.name, tostring(change.package.version))
        handleMap[change] = handle
    end

    self.changes = changes
    self.changeHandleMap = handleMap
end

function ChangeListPresenter:_onApplying()
    local view = self.view

    view:enableButton('cancel')

    local tasks = PackageManager.applyChanges(self.changes)
    self.changeTaskMap = tasks
    self.applyingChanges = true
    self:updateUpdateFrequency()

    local changeHandleMap = self.changeHandleMap
    for change, task in pairs(tasks) do
        local viewHandle = assert(changeHandleMap[change])
        task.events.downloadStarted = function()
            view:freeze()
            view:setChangeTotalBytes(viewHandle, task.downloadTask.properties.totalBytes)
            view:thaw()
        end
        task.events.complete = function()
            view:freeze()
            view:markChangeAsCompleted(viewHandle)
            if AllTasksAreComplete(tasks) then
                self.state:complete()
            end
            view:thaw()
        end
    end
end

function ChangeListPresenter:_onCancelApplying()
    error('Cancel isn\'t implemented currently.')
end

function ChangeListPresenter:_onDone()
    local view = self.view
    view:enableButton('complete')
    view:markAsCompleted()

    self:updateProgress()

    self.changeTaskMap = {}
    self:updateUpdateFrequency()
end

return function( view,
                 requirementListPresenter,
                 packageDbUpdated,
                 statusBarPresenter,
                 mainFrameView,
                 updateTimer )
    local self = setmetatable({}, ChangeListPresenter)
    self.view = view
    self.statusBarPresenter = statusBarPresenter
    self.mainFrameView = mainFrameView
    self.updateTimer = updateTimer
    self.dirty = false
    self.changeHandleMap = {}
    self.changeTaskMap = {}

    self.state = statemachine.create
    {
        initial = 'empty',
        events =
        {
            {name = 'gatheredChanges', from = 'empty',    to = 'ready'},
            {name = 'start',           from = 'ready',    to = 'applying'},
            {name = 'cancel',          from = 'applying', to = 'done'},
            {name = 'complete',        from = 'applying', to = 'done'},
            {name = 'reset',           from = {'empty',
                                               'ready',
                                               'done'},   to = 'empty'}
        },
        callbacks =
        {
            onempty    = bind(self._onEmpty, self),
            onready    = function( state, event, from, to, ... ) return self:_onReady(...) end,
            onapplying = bind(self._onApplying, self),
            oncancel   = bind(self._onCancel, self),
            ondone     = bind(self._onDone, self),
        }
    }

    view.applyButtonPressEvent:addListener(function()
        view:freeze()
        self.state:start()
        view:thaw()
    end)

    view.cancelButtonPressEvent:addListener(function()
        view:freeze()
        self.state:cancel()
        view:thaw()
    end)

    view.completeButtonPressEvent:addListener(function()
        view:freeze()
        self.state:reset()
        view:thaw()
    end)

    view.showUpgradeInfoEvent:addListener(function( packageName, packageVersion )
        local frame = xrc.createFrame('upgradeInfo', mainFrameView.frame)
        frame:Show()
        -- TODO
    end)

    local function Refresh()
        view:freeze()
        self:resetOrGatherChanges()
        view:thaw()
        self.dirty = false
    end

    local function RefreshOrMarkDirty()
        if mainFrameView:getCurrentPageView() == view then
            if self.state:can('reset') then
                Refresh()
            end
        else
            -- page is currently not visible
            self.dirty = true
        end
    end

    requirementListPresenter.requirementsChanged:addListener(RefreshOrMarkDirty)
    packageDbUpdated:addListener(RefreshOrMarkDirty)

    mainFrameView.pageChanged:addListener(function( pageView )
        if pageView == view then
            if self.dirty and self.state:can('reset') then
                Refresh()
            end
            if self.state:is('applying') then
                view:freeze()
                self:updateProgress()
                view:thaw()
            end
        end
        self:updateUpdateFrequency()
    end)

    updateTimer.updateEvent:addListener(function()
        if mainFrameView:getCurrentPageView() == view and self.state:is('applying') then
            view:freeze()
            self:updateProgress()
            view:thaw()
        end
    end)

    view:freeze()
    self:resetOrGatherChanges()
    view:thaw()

    return self
end
