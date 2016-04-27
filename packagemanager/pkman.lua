local Misc         = require 'packagemanager/misc'
local Config       = require 'packagemanager/config'
local LocalPackage = require 'packagemanager/localpackage'
local Repository   = require 'packagemanager/repository'
local PackageDB    = require 'packagemanager/packagedb'
local Dependency   = require 'packagemanager/dependency'
local Version      = require 'packagemanager/version'


local pkman = {}

function pkman.buildPackageDB( options )
    local db = {}
    if options.localPackages then
        LocalPackage.gatherInstalledPackages(db, Config.searchPaths)
    end
    if options.remotePackages then
        for repoName, _ in pairs(Config.repositories) do
            local repoDB = Repository.loadRepoDatabase(repoName)
            PackageDB.mergeDatabases(db, repoDB)
        end
    end
    return db
end

local function PackageIteratorCoro( db )
    for _, versions in pairs(db) do
        for _, version in pairs(versions) do
            coroutine.yield(version)
        end
    end
end

function pkman.iterPackages( db )
    return coroutine.wrap(function() PackageIteratorCoro(db) end)
end

function pkman.updateRepos()
    for name, url in pairs(Config.repositories) do
        Repository.updateRepo(name, url)
    end
end

local function PostprocessRequirementGroup( requirementGroup )
    requirementGroup = Misc.copyTable(requirementGroup)
    -- Parse version ranges:
    for packageName, versionRangeStr in pairs(requirementGroup) do
        local versionRange = Version.parseVersionRange(versionRangeStr)
        requirementGroup[packageName] = versionRange
    end
    return requirementGroup
end

function pkman.markUserRequirements( db )
    for index, requirementGroup in ipairs(Config.requirements) do
        requirementGroup = PostprocessRequirementGroup(requirementGroup)
        local success, result = pcall(Dependency.resolve, db, requirementGroup)
        if success then
            for _, package in pairs(result) do
                package.required = true
            end
        else
            print(string.format('Can\'t resolve user requirement group %d: %s', index, result))
        end
    end
end

function pkman.installRequirements( db )
    local outstandingPackages = {}

    for index, requirementGroup in ipairs(Config.requirements) do
        requirementGroup = PostprocessRequirementGroup(requirementGroup)
        local success, result = pcall(Dependency.resolve, db, requirementGroup)
        if success then
            for _, package in pairs(result) do
                if not package.localFileName then
                    local key = package.name..tostring(package.version)
                    outstandingPackages[key] = package
                end
            end
        else
            print(string.format('Can\'t resolve user requirement group %d: %s', index, result))
        end
    end

    print('Packages that need to be downloaded:')
    for _, package in pairs(outstandingPackages) do
        print(string.format('%s %s', package.name, package.version))
    end

    for _, package in pairs(outstandingPackages) do
        Repository.installPackage(package, Config.installPath)
    end
end

function pkman.getPackageInstallationStatus( package )
    if package.required and package.localFileName then
        return 'installed'
    elseif package.required then
        return 'required'
    elseif package.localFileName then
        return 'obsolete'
    else
        return ''
    end
end

function pkman.removeObsoletePackages( db )
    for package in pkman.iterPackages(db) do
        if not package.required and package.localFileName then
            print(string.format('%s %s', package.name, package.version))
            LocalPackage.remove(db, package)
        end
    end
end


return pkman
