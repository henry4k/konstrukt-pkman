local ChangeListController = {}
ChangeListController.__index = ChangeListController

return function( view )
    local self = setmetatable({}, ChangeListController)
    self.view = view

    view.applyButtonPressEvent:addListener(function()
        self.view:enableApplyButton(false)
        self.view:enableAbortButton(true)

        self.view:addInstallEntry('test', '0.1.0')
    end)

    view.abortButtonPressEvent:addListener(function()
        self.view:enableApplyButton(true)
        self.view:enableAbortButton(false)
    end)

    view.showUpgradeInfoEvent:addListener(function( packageName, packageVersion )
        print('showUpgradeInfo', packageName, packageVersion)
    end)

    return self
end
