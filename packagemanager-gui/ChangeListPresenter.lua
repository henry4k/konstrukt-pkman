local PackageManager = require 'packagemanager/init'


local ChangeListPresenter = {}
ChangeListPresenter.__index = ChangeListPresenter

function ChangeListPresenter:gatherChanges()
    assert(not self.applyingChanges, 'Currently applying changes.')
    self.changes = PackageManager.gatherChanges()
    local view = self.view
    view:clearChanges()
    local handleMap = {}
    self.changeHandleMap = handleMap
    for _, change in ipairs(self.changes) do
        local handle = view:addInstallChange(change.package.name, tostring(change.package.version))
        handleMap[change] = handle
    end
end

function ChangeListPresenter:apply()
    assert(not self.applyingChanges, 'Already applying changes.')
    local tasks = PackageManager.applyChanges(self.changes)
    self.changeTaskMap = tasks
    --[[
    for change, task in pairs(tasks) do
        local viewHandle = assert(changeHandleMap[change])
        print('STARTED', task.status)
        task.events.complete = function()
            print('COMPLETED')
        end
        task.events.fail = function()
            print('FAILED')
        end
    end
    ]]
    self.applyingChanges = true
    self.view:enableButton('cancel')
end

function ChangeListPresenter:cancel()
    assert(self.applyingChanges, 'Not applying changes.')
    error('Cancel isn\'t implemented currently.')
    self:complete()
end

function ChangeListPresenter:updateProgress()
    local view = self.view
    if self.mainFrameView:getCurrentPageView() == view then
        local changeHandleMap = self.changeHandleMap
        for change, task in pairs(self.changeTaskMap) do
            local viewHandle = assert(changeHandleMap[change])
            local downloadTask = task.downloadTask
            if downloadTask then
                local properties = downloadTask.properties
                local bytesWritten = properties.bytesWritten
                local totalBytes   = properties.totalBytes
                if bytesWritten then
                    view:updateChange(viewHandle,
                                      bytesWritten,
                                      totalBytes)
                end
            end
        end
    end
end

function ChangeListPresenter:_complete()
    self.applyingChanges = false
    self.changeTaskMap = {}
    view:enableButton('apply')
    self:gatherChanges()
end

return function( view, requirementListPresenter, mainFrameView, timerEvent )
    local self = setmetatable({}, ChangeListPresenter)
    self.view = view
    self.mainFrameView = mainFrameView
    self.requirementsChanged = false
    self.applyingChanges = false
    self.changeHandleMap = {}
    self.changeTaskMap = {}

    view.applyButtonPressEvent:addListener(function()
        view:freeze()
        self:apply()
        view:thaw()
    end)

    view.cancelButtonPressEvent:addListener(function()
        view:freeze()
        self:cancel()
        view:thaw()
    end)

    view.showUpgradeInfoEvent:addListener(function( packageName, packageVersion )
        print('showUpgradeInfo', packageName, packageVersion)
    end)

    requirementListPresenter.requirementsChanged:addListener(function()
        if mainFrameView:getCurrentPageView() == view then
            -- TODO: dont do this while updating
            view:freeze()
            self:gatherChanges()
            view:thaw()
        else
            -- page is currently not visible
            self.requirementsChanged = true
        end
    end)

    mainFrameView.pageChanged:addListener(function( pageView )
        if pageView == view then
            if self.requirementsChanged then
                -- TODO: dont do this while updating
                view:freeze()
                self:gatherChanges()
                view:thaw()
                self.requirementsChanged = false
            end
        end
    end)

    timerEvent:addListener(function()
        self:updateProgress()
    end)

    view:freeze()
    self:gatherChanges()
    view:enableButton('apply')
    view:thaw()

    return self
end
