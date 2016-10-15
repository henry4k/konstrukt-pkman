local SearchPresenter = {}
SearchPresenter.__index = SearchPresenter

return function( view )
    local self = setmetatable({}, SearchPresenter)
    self.view = view

    view.searchChangeEvent:addListener(function()
        view:freeze()
            view:clearResults()
            view:addResultEntry('available', view:getQuery(), '0.0.0')
            view:addResultEntry('installed-updated', view:getQuery(), '0.0.0')
            view:addResultEntry('install', view:getQuery(), '0.0.0')
            view:addResultEntry('remove', view:getQuery(), '0.0.0')
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
