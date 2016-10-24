local PackageManager = require 'packagemanager/init'


local ScenarioPresenter = {}
ScenarioPresenter.__index = ScenarioPresenter

local function ExecuteQuery( view, query )
    local scenarios = PackageManager.getScenarios()
    local results = {}
    for _, scenario in ipairs(scenarios) do
        if scenario.name:match(query) then
            table.insert(results, scenario)
        end
    end

    local resultList = view.resultList
    resultList:freeze()
        resultList:clear()
        for _, scenario in ipairs(results) do
            resultList:addRow(scenario,
                              {{ text = scenario.type,
                                 value = scenario.type },
                               { text = scenario.name,
                                 value = scenario.name },
                               { text = '',
                                 value = 0 }})
        end
        resultList:sort()
        resultList:adaptColumnWidths()
    resultList:thaw()
end

return function( view )
    local self = setmetatable({}, ScenarioPresenter)
    self.view = view

    view.searchChangeEvent:addListener(function()
        local query = view:getQuery()
        ExecuteQuery(view, query)
    end)

    view.resultList.rowFocusChangeEvent:addListener(function( scenario )
        view:freeze()
        if scenario then
            view:setName(scenario.name)
            view:setDescription(scenario.description)
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
