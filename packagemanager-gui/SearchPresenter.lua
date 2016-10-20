local PackageManager = require 'packagemanager/init'


local SearchPresenter = {}
SearchPresenter.__index = SearchPresenter

local function GetPackageStatus( package )
    if package.virtual then
        package = package.provider
    end

    if package.required then
        if package.localFileName then
            return 'installed-updated'
        else
            return 'install'
        end
    else
        if package.localFileName then
            return 'remove'
        else
            return 'available'
        end
    end
end

return function( view )
    local self = setmetatable({}, SearchPresenter)
    self.view = view

    view.searchChangeEvent:addListener(function()
        local query = view:getQuery()
        local results = PackageManager.searchWithQueryString(query)

        view:freeze()
            view:clearResults()
            for _, package in ipairs(results) do
                view:addResultEntry(GetPackageStatus(package), package.name, tostring(package.version))
            end
        view:thaw()
    end)

    view.searchEditEvent:addListener(function()
        print('edit search not implemented yet')
        view:setQuery('loljk')
    end)

    view.columnClickEvent:addListener(function( column )
        view:sort(column, 'ascending')
        view:adaptColumnWidths()
    end)

    return self
end
