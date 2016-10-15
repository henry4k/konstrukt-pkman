local PackageManager = require 'packagemanager/init'


local ChangeListPresenter = {}
ChangeListPresenter.__index = ChangeListPresenter

function ChangeListPresenter:gatherChanges()
    self.changes = PackageManager.gatherChanges()
    local view = self.view
    view:clearChanges()
    for _, change in ipairs(self.changes) do
        view:addInstallChange(change.package.name, tostring(change.package.version))
    end
    -- PackageManager.applyChanges()
end

return function( view )
    local self = setmetatable({}, ChangeListPresenter)
    self.view = view

    local statusField

    view.applyButtonPressEvent:addListener(function()
        view:freeze()
            view:enableApplyButton(false)
            view:enableCancelButton(true)
            self:gatherChanges()
        view:thaw()
    end)

    view.cancelButtonPressEvent:addListener(function()
        view:freeze()
            view:enableApplyButton(true)
            view:enableCancelButton(false)
        view:thaw()
    end)

    view.showUpgradeInfoEvent:addListener(function( packageName, packageVersion )
        print('showUpgradeInfo', packageName, packageVersion)
    end)

    return self
end
