local misc = require 'packagemanager/misc'
local version = require 'packagemanager/version'
local PackageManager = require 'packagemanager/init'
local Event = require 'packagemanager-gui/Event'


local RequirementListPresenter = {}
RequirementListPresenter.__index = RequirementListPresenter

function RequirementListPresenter:executeQuery( query )
    local view = self.view
    local requirements = PackageManager.getRequirements()
    local results = {}
    for _, requirement in ipairs(requirements) do
        if requirement.packageName:match(query) then
            table.insert(results, requirement)
        end
    end

    -- TODO: Sort by name

    view:freeze()
        view:clear()
        for _, requirement in ipairs(results) do
            view:addRequirement(requirement)
        end
    view:thaw()
end

local function FindRequirement( requirement )
    local requirements = PackageManager.getRequirements()
    for i = 1, #requirements do
        if misc.tablesAreEqual(requirement, requirements[i]) then
            return i
        end
    end
end

function RequirementListPresenter:tryRemoveRequirement( requirement )
    local index = FindRequirement(requirement)
    if index then
        local requirements = PackageManager.getRequirements()
        table.remove(requirements, index)
        PackageManager.setRequirements(requirements)
        self.requirementsChanged()
    end
end

function RequirementListPresenter:addOrUpdateRequirement( requirement )
    local requirements = PackageManager.getRequirements()
    local index = FindRequirement(requirement)
    if not index then
        table.insert(requirements, requirement)
    end
    PackageManager.setRequirements(requirements)
    self.requirementsChanged()
end

function RequirementListPresenter:destroy()
end

local function CheckVersionRange( versionRangeExpr )
    return pcall(version.parseVersionRange(versionRangeExpr))
end

return function( view )
    local self = setmetatable({}, RequirementListPresenter)
    self.view = view
    self.requirementsChanged = Event()

    view.searchChangeEvent:addListener(function()
        self:executeQuery(view:getQuery())
    end)

    view.addRequirementEvent:addListener(function()
        -- Valid requirements are added in changeRequirementEvent.
        view:freeze()
        view:addRequirement({ packageName = '', versionRange = '' })
        view:thaw()
    end)

    view.removeRequirementEvent:addListener(function( requirement )
        self:tryRemoveRequirement(requirement)
        view:freeze()
        view:removeRequirement(requirement)
        view:thaw()
    end)

    view.changeRequirementEvent:addListener(function( requirement,
                                                      newPackageName,
                                                      newVersionRangeExpr )
        view:freeze()
        local versionRangeOk, versionRangeOrErr =
            pcall(version.parseVersionRange, newVersionRangeExpr)

        if versionRangeOk then
            view:setVersionRangeHint(requirement, 'none')
        else
            view:setVersionRangeHint(requirement, 'error', versionRangeOrErr)
        end

        if #newPackageName > 0 and versionRangeOk then
            requirement.packageName = newPackageName
            requirement.versionRange = versionRangeOrErr
            self:addOrUpdateRequirement(requirement)
        end
        view:thaw()
    end)

    view:freeze()
    view:setQuery('')
    self:executeQuery('')
    view:thaw()

    return self
end
