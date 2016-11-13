local PackageManager = require 'packagemanager/init'


local PackageListPresenter = {}
PackageListPresenter.__index = PackageListPresenter

local function GetPackageStatus( package, isRequired )
    if package.virtual then
        package = package.provider
    end

    if isRequired then
        if package.localFileName then
            return 'package-installed-updated', 1
        else
            return 'package-install', 2
        end
    else
        if package.localFileName then
            return 'package-uninstall', 3
        else
            return 'package-available', 4
        end
    end
end

local function ExecuteQuery( view, query )
    local results = PackageManager.searchWithQueryString(query)
    local resultList = view.resultList

    local requiredPackages = PackageManager.gatherRequiredPackages()

    resultList:freeze()
        resultList:clear()
        for _, package in ipairs(results) do
            local statusIcon, statusSortValue = GetPackageStatus(package, requiredPackages[package])
            resultList:addRow(package,
                              {{ icon = statusIcon,
                                 value = statusSortValue },
                               { text = package.name,
                                 value = package.name },
                               { text = tostring(package.version),
                                 value = package.version },
                               { text = '',
                                 value = 0 }})
        end
        resultList:sort()
        resultList:adaptColumnWidths()
    resultList:thaw()
end

function PackageListPresenter:destroy()
end

return function( view, requirementListPresenter, mainFrameView )
    local self = setmetatable({}, PackageListPresenter)
    self.view = view
    self.requirementsChanged = false

    view.searchChangeEvent:addListener(function()
        view:freeze()
        local query = view:getQuery()
        ExecuteQuery(view, query)
        view:thaw()
    end)

    local currentPackage

    view.resultList.rowFocusChangeEvent:addListener(function( package )
        view:freeze()
        if package then
            view:setName(package.name)
            view:setDescription(package.description or '')
            view:enableLaunchButton(package.type == 'scenario')
            view:enableDeleteButton(false) -- There are no user created packages yet
            view:enableReloadButton(false) -- dito
            view:enableSaveButton(false) -- dito
            view:enableDetailsPanel(true)
        else
            view:setName('')
            view:setDescription('')
            view:enableDetailsPanel(false)
        end
        view:thaw()
        currentPackage = package
    end)

    view.launchEvent:addListener(function()
        assert(currentPackage)
        assert(currentPackage.type == 'scenario')
        PackageManager.launchScenario(currentPackage)
    end)


    requirementListPresenter.requirementsChanged:addListener(function()
        if mainFrameView:getCurrentPageView() == view then
            view:freeze()
            local query = view:getQuery()
            ExecuteQuery(view, query)
            view:thaw()
        else
            -- page is currently not visible
            self.requirementsChanged = true
        end
    end)

    mainFrameView.pageChanged:addListener(function( pageView )
        if pageView == view and self.requirementsChanged then
            view:freeze()
            local query = view:getQuery()
            ExecuteQuery(view, query)
            view:thaw()
            self.requirementsChanged = false
        end
    end)

    view:freeze()
    view.resultList:sort(2, 'ascending')
    view:setQuery('')
    ExecuteQuery(view, '')
    view:thaw()

    return self
end
