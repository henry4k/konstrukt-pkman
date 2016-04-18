local versionutils = require 'versionutils'


local dependencyutils = {}

--- Current version range, as defined users of the package.
local function GetDependencyVersionRange( dependency )
    local range
    for _, userVersionRange in pairs(dependency.users) do
        if range then
            range = assert(versionutils.mergeVersionRanges(range, userVersionRange))
        else
            range = userVersionRange
        end
    end
    return range
end

local function SelectPackageInVersionRange( ctx, packageName, versionRange )
    local versions = assert(ctx.db[packageName], 'Package not available.')
    local matchingVersions =
        versionutils.getMatchingPackages(versions, versionRange)
    -- TODO: Sort
    return matchingVersions[1] -- could be nil, which is okay
end

local AddDependency
local RemoveDependency

local function UpdateDependency( ctx, dependencyName )
    local dependency = assert(ctx.dependencies[dependencyName])

    RemoveDependencyUser(ctx, dependencyName)

    local mergedVersionRange = GetDependencyVersionRange(dependency)
    dependency.package = SelectPackageInVersionRange(ctx,
                                                     dependencyName,
                                                     mergedVersionRange)
    assert(dependency.package.name) -- sanity check

    -- Add dependencies of this dependency
    for packageName, versionRange in pairs(dependency.package.dependencies) do
        AddDependency(ctx, packageName, dependency.package.name, versionRange)
    end
end

--- Add a new dependency.
AddDependency = function( ctx, dependencyName, userName, userVersionRange )
    print('AddDependency       ', dependencyName..' '..userName)
    local dependency = ctx.dependencies[dependencyName]
    if not dependency then
        dependency =
        {
            users = {},
            package = nil
        }
        ctx.dependencies[dependencyName] = dependency
    end

    assert(not dependency.users[userName], 'User already declared this dependency.')
    dependency.users[userName] = userVersionRange

    UpdateDependency(ctx, dependencyName)
end

RemoveDependencyUser = function( ctx, userName )
    print('RemoveDependencyUser', userName)
    -- Remove user from all dependency entries:
    for _, dependency in pairs(ctx.dependencies) do
        dependency.users[userName] = nil
    end

    -- Clear empty dependency entries:
    for dependencyName, dependency in pairs(ctx.dependencies) do
        if not next(dependency.users) then
            ctx.dependencies[dependencyName] = nil
        end
    end
end

--- Compute list, which statisfies all dependencies.
function dependencyutils.resolveDependencies( db, packageName, versionRange )
    local ctx =
    {
        -- TODO: Sorting info goes here
        db = db,
        dependencies = {}
    }
    --AddDependency(ctx, packageName, '_forced', versionRange)
    print(xpcall(AddDependency, debug.traceback, ctx, packageName, '_forced', versionRange))
    return ctx.dependencies -- DEBUG
end


return dependencyutils
