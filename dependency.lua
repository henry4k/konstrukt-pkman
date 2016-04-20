local Misc = require 'misc'
local Version = require 'version'


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
        selectedPackageVersions = Misc.copyTable(ctx.selectedPackageVersions),
        openRequirements = Misc.copyTable(ctx.openRequirements)
    }
end

local function SortRequirements( requirements )
    -- TODO
end

local function GetAvailableVersions( ctx, requirement )
    local version = ctx.selectedPackageVersions[requirement.packageName]
    if version then
        -- we already selected a version so we can't pick a different
        return {version}
    else
        -- we didn't select a version yet so all versions are possible
        local packageVersions = ctx.db[requirement.packageName]
        if not packageVersions then
            error(string.format('Package %s not available.', requirement.packageName))
        end
        local versions = {}
        for _, version in pairs(packageVersions) do
            table.insert(versions, version)
        end
        if #versions == 0 then
            error(string.format('Package %s is empty.', requirement.packageName)) -- This should not happen.
        end
        return versions
    end
end

local function GetCompatibleVersions( ctx, requirement )
    local available = GetAvailableVersions(ctx, requirement)
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
        local compatibleVersions = GetCompatibleVersions(ctx, requirement)
        local conflictResolution = nil
        for _, version in ipairs(compatibleVersions) do
            if not conflictResolution then
                local newCtx = CopyContext(ctx)
                newCtx.selectedPackageVersions[requirement.packageName] = version
                AddDependenciesAsRequirements(newCtx, version.dependencies)
                conflictResolution = ResolveRequirement(newCtx)
            else
                break
            end
        end
        return conflictResolution
    else
        return ctx.selectedPackageVersions
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
        selectedPackageVersions = {},
        openRequirements = {}
    }
    AddDependenciesAsRequirements(ctx, dependencies)
    return ResolveRequirement(ctx)
end


return Dependency
