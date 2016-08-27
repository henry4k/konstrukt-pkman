local SearchController = {}
SearchController.__index = SearchController

return function( view )
    local self = setmetatable({}, SearchController)
    self.view = view

    view.searchChangeEvent:addListener(function()
        view:freeze()
            view:clearResults()
            view:addResultEntry('available', view:getQuery(), '0.0.0')
        view:thaw()
    end)

    view.searchEditEvent:addListener(function()
        print('edit search not implemented yet')
        view:setQuery('loljk')
    end)

    return self
end
