local RequirementGroupsController = {}
RequirementGroupsController.__index = RequirementGroupsController

return function( view )
    local self = setmetatable({}, RequirementGroupsController)
    self.view = view

    view.createGroupEvent:addListener(function()
        view:freeze()
            local name = 'Group'
            view:addGroupEntry(name)
            view:selectGroupEntry(name)
        view:thaw()
    end)

    view.removeGroupEvent:addListener(function( name )
        view:freeze()
            view:removeGroupEntry(name)
        view:thaw()
    end)

    view.renameGroupEvent:addListener(function( oldName, newName )
        view:freeze()
            view:renameGroupEntry(oldName, newName)
        view:thaw()
    end)

    view.addRequirementEvent:addListener(function( groupName )
        view:freeze()
            for i = 1, 30 do
                view:addRequirementEntry(groupName, 'abc >= 1.2.3')
            end
            view:showRequirementEntry(groupName, nil)
        view:thaw()
    end)

    view.removeRequirementEvent:addListener(function( groupName, entry )
        view:freeze()
            view:removeRequirementEntry(groupName, entry)
        view:thaw()
    end)

    return self
end
