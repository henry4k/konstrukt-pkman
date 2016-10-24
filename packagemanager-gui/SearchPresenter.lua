local PackageManager = require 'packagemanager/init'


local SearchPresenter = {}
SearchPresenter.__index = SearchPresenter

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
                                 value = package.version }})
        end
        resultList:sort()
        resultList:adaptColumnWidths()
    resultList:thaw()
end

return function( view )
    local self = setmetatable({}, SearchPresenter)
    self.view = view

    view.searchChangeEvent:addListener(function()
        local query = view:getQuery()
        ExecuteQuery(view, query)
    end)

    view:freeze()
    view.resultList:sort(2, 'ascending')
    view:setQuery('')
    ExecuteQuery(view, '')
    view:thaw()

    return self
end
