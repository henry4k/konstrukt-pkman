local RequirementGroupsPresenter = {}
RequirementGroupsPresenter.__index = RequirementGroupsPresenter

return function( view, model )
    local self = setmetatable({}, RequirementGroupsPresenter)
    self.view = view
    self.model = model

    view.createGroupEvent:addListener(function()
        view:freeze()
            local name = 'Group'
            local group = view:addGroup(name)
            view:selectGroup(group)
        view:thaw()
    end)

    view.removeGroupEvent:addListener(function( group )
        view:freeze()
            view:removeGroup(group)
        view:thaw()
    end)

    view.renameGroupEvent:addListener(function( group, newName )
        view:freeze()
            view:renameGroup(group, newName)
        view:thaw()
    end)

    view.addRequirementEvent:addListener(function( group )
        view:freeze()
            for i = 1, 30 do
                view:addRequirement(group, 'abc >= 1.2.3')
            end
            view:showRequirement(group, nil)
        view:thaw()
    end)

    view.removeRequirementEvent:addListener(function( group, requirement )
        view:freeze()
            view:removeRequirement(group, requirement)
        view:thaw()
    end)

    return self
end
