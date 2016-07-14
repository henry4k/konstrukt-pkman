local RequirementGroupsController = {}
RequirementGroupsController.__index = RequirementGroupsController

return function( view )
    local self = setmetatable({}, RequirementGroupsController)
    self.view = view

    view.createGroupEvent:addListener(function()
        local name = 'Group'
        view:addGroupEntry(name)
        view:selectGroupEntry(name)
    end)

    view.removeGroupEvent:addListener(function( name )
        view:removeGroupEntry(name)
    end)

    view.renameGroupEvent:addListener(function( oldName, newName )
        print('renameGroup', oldName, newName)
    end)

    view.addRequirementEvent:addListener(function( groupName )
        local entry = view:addRequirementEntry(groupName, 'abc >= 1.2.3')
        view:showRequirementEntry(groupName, entry)
    end)

    view.removeRequirementEvent:addListener(function( groupName, entry )
        view:removeRequirementEntry(groupName, entry)
    end)

    return self
end
