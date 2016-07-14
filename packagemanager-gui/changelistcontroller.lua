local ChangeListController = {}
ChangeListController.__index = ChangeListController

return function( view )
    local self = setmetatable({}, ChangeListController)
    self.view = view

    view.applyButtonPressEvent:addListener(function()
        view:freeze()
            view:enableApplyButton(false)
            view:enableCancelButton(true)
            view:addInstallChange('test', '0.1.0')
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
