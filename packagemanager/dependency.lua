local Misc    = require 'packagemanager/misc'
local Version = require 'packagemanager/version'


-- Requirement:
-- {
--     packageName = ...,
--     versionRange = ...,
-- }


local Dependency = {}

local function CopyContext( ctx )
    return
    {
        db = ctx.db,
        selectedPackages = Misc.copyTable(ctx.selectedPackages),
        openRequirements = Misc.copyTable(ctx.openRequirements)
    }
end

local function SortRequirements( requirements )
    -- TODO
end

local function GetAvailablePackages( ctx, requirement )
    local selectedPackage = ctx.selectedPackages[requirement.packageName]
    if selectedPackage then
        -- we already selected a package so we can't pick a different
        return {selectedPackage}
    else
        -- we didn't select a package yet so all packages are possible
        local packageVersions = ctx.db[requirement.packageName]
        if not packageVersions then
            error(string.format('Package %s not available.', requirement.packageName))
        end
        local packages = {}
        for _, package in pairs(packageVersions) do
            table.insert(packages, package)
        end
        if #packages == 0 then
            error(string.format('Package %s is empty.', requirement.packageName)) -- This should not happen.
        end
        return packages
    end
end

local function GetCompatiblePackages( ctx, requirement )
    local available = GetAvailablePackages(ctx, requirement)
    return Version.getMatchingPackages(available, requirement.versionRange)
end

---
-- @param dependencies
-- <package name> = <version range>
local function AddDependenciesAsRequirements( ctx, dependencies )
    for packageName, versionRange in pairs(dependencies) do
        local requirement =
        {
            packageName = packageName,
            versionRange = versionRange
        }
        table.insert(ctx.openRequirements, requirement)
    end
    SortRequirements(ctx.openRequirements)
end


--- Takes the last requirement and tries to resolve it.
-- Returns either nil, if resolution failed, or a package table.
local function ResolveRequirement( ctx )
    local requirement = table.remove(ctx.openRequirements)
    if requirement then
        local compatiblePackages = GetCompatiblePackages(ctx, requirement)
        local conflictResolution = nil
        for _, package in ipairs(compatiblePackages) do
            if not conflictResolution then
                local newCtx = CopyContext(ctx)
                newCtx.selectedPackages[requirement.packageName] = package
                AddDependenciesAsRequirements(newCtx, package.dependencies)
                conflictResolution = ResolveRequirement(newCtx)
            else
                break
            end
        end
        return conflictResolution
    else
        return ctx.selectedPackages
    end
end

--- Compute list, which statisfies all dependencies.
--
-- @param dependencies
-- <package name> = <version range>
function Dependency.resolve( db, dependencies )
    local ctx =
    {
        db = db,
        selectedPackages = {},
        openRequirements = {}
    }
    AddDependenciesAsRequirements(ctx, dependencies)
    return assert(ResolveRequirement(ctx), '???')
end


return Dependency
