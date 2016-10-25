local PackageManager = require 'packagemanager/init'


local RequirementListPresenter = {}
RequirementListPresenter.__index = RequirementListPresenter

local function ExecuteQuery( view, query )
    local requirements = PackageManager.getRequirements()
    local results = {}
    for _, requirement in ipairs(requirements) do
        if requirement.name:match(query) then
            table.insert(results, requirement)
        end
    end

    -- TODO: Sort by name

    view:freeze()
        view:clear()
        for _, requirement in ipairs(results) do
            view:addRequirement(requirement.name, tostring(requirement.versionRange))
        end
    view:thaw()
end

return function( view )
    local self = setmetatable({}, RequirementListPresenter)
    self.view = view

    view.searchChangeEvent:addListener(function()
        local query = view:getQuery()
        ExecuteQuery(view, query)
    end)

    view.addRequirementEvent:addListener(function()
        view:freeze()
        view:addRequirement('', '')
        view:thaw()
    end)

    view.removeRequirementEvent:addListener(function( requirement )
        view:freeze()
        view:removeRequirement(requirement)
        view:thaw()
    end)

    view:freeze()
    view:setQuery('')
    ExecuteQuery(view, '')
    view:thaw()

    return self
end
