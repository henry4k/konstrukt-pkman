local PackageManager = require 'packagemanager/init'


local PackageListPresenter = {}
PackageListPresenter.__index = PackageListPresenter

local function GetPackageStatus( package )
    if package.virtual then
        package = package.provider
    end

    if package.required then
        if package.localFileName then
            return 'package-installed-updated', 1
        else
            return 'package-install', 2
        end
    else
        if package.localFileName then
            return 'package-remove', 3
        else
            return 'package-available', 4
        end
    end
end

local function ExecuteQuery( view, query )
    local results = PackageManager.searchWithQueryString(query)
    local resultList = view.resultList

    resultList:freeze()
        resultList:clear()
        for _, package in ipairs(results) do
            local statusIcon, statusSortValue = GetPackageStatus(package)
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

return function( view )
    local self = setmetatable({}, PackageListPresenter)
    self.view = view

    view.searchChangeEvent:addListener(function()
        local query = view:getQuery()
        ExecuteQuery(view, query)
    end)

    view.resultList.rowFocusChangeEvent:addListener(function( package )
        view:freeze()
        if package then
            view:setName(package.name)
            view:setDescription(package.description or '')
            view:enableDetailsPanel(true)
        else
            view:setName('')
            view:setDescription('')
            view:enableDetailsPanel(false)
        end
        view:thaw()
    end)

    view:freeze()
    view.resultList:sort(2, 'ascending')
    view:setQuery('')
    ExecuteQuery(view, '')
    view:thaw()

    return self
end
