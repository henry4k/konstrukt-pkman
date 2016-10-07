-- vim: set foldmethod=marker:
-- High level interface to the package manager:

local Config = require 'packagemanager/config'
local Repository = require 'packagemanager/repository'
local DownloadManager = require 'packagemanager/downloadmanager'
local LocalPackage = require 'packagemanager/localpackage'
local Dependency = require 'packagemanager/dependency'
local PackageDB = require 'packagemanager/packagedb'
local Package = require 'packagemanager/package'
local FS = require 'packagemanager/fs'


local PackageManager = {}
local db

-- General stuff {{{1

local function buildPackageDB( options )
    local db = PackageDB.create()
    if options.localPackages then
        LocalPackage.gatherInstalledPackages(db, Config.searchPaths)
    end
    if options.remotePackages then
        for repoName, _ in pairs(Config.repositories) do
            Repository.loadIndex(db, repoName)
        end
    end
    return db
end

function PackageManager.initialize( configFileName )
    Config.load(configFileName)
    db = buildPackageDB{localPackages=true, remotePackages=true}
end

function PackageManager.finalize()
    DownloadManager.finalize()
    Config.save()
end

function PackageManager.update()
    DownloadManager.update()
end

function PackageManager.updateRepositoryIndices()
    local jobs = {}
    for name, url in pairs(Config.repositories) do
        local job = Repository.updateIndex(name, url)
        table.insert(jobs, job)
    end
    return jobs -- TODO: And then?
end


-- Read/edit requirement groups {{{1

function PackageManager.getRequirementGroupNames()
    local names = {}
    for name, _ in pairs(Config.requirements) do
        table.insert(names, name)
    end
    return names
end

function PackageManager.getRequirementGroup( name )
    local group = Config.requirements[name]
    if group then
        return group
    else
        return nil, string.format('Requirement group %s doesn\'t exist.', name)
    end
end

-- Replaces or removes a requirement group.
function PackageManager.setRequirementGroup( name, group )
    -- TODO: Validate new group either here or in Config.
    Config.requirements[name] = group
end


-- Query database {{{1

--- ...
--
-- @param[type=table] comparators
-- TODO
--
-- @param[type=table] options
-- `local` controls whether installed packages are searched.  Defaults to `true`.
-- `remote` controls whether packages from repositories are searched.  Defaults to `true`.
--
function PackageManager.search( comparators, options )
end


-- Query and apply changes {{{1

-- Build change list.
--
-- @return
-- A list that contains the gathered changes or `nil` together with an error
-- message if something went wrong.
-- Each change looks like this: `{ type = [install, uninstall], package = ... }`
function PackageManager.gatherChanges()
    local neededPackages = {}
    for groupName, group in pairs(Config.requirements) do
        local packages = assert(Dependency.resolve(db, group))
        for _, package in pairs(packages) do
            if not package.localFileName and not package.virtual then
                neededPackages[package] = true
            end
        end
    end

    local changes = {}
    for package, _ in pairs(neededPackages) do
        table.insert(changes, { type = 'install', package = package })
    end

    -- TODO: Gather obsolete packages too!

    return changes
end

local function ResumeCoroutineAndPropagateErrors( coro, ... )
    local returnValues = {coroutine.resume(coro, ...)}
    local success = returnValues[1]
    if not success then
        error(returnValues[2])
    else
        return table.unpack(returnValues, 2)
    end
end

local function SuspendCoroTillJobIsDone( job )
    if job.status == 'waiting' or
       job.status == 'running' then
        local coro, isMainCoro = coroutine.running()
        assert(not isMainCoro)
        job.eventHandler.finish = function()
            ResumeCoroutineAndPropagateErrors(coro)
        end
        coroutine.yield()
   end
end

local ChangeCoroFunctions = {}
function ChangeCoroFunctions.install( change )
    local package = change.package
    assert(package.downloadUrl, 'Package misses a download URL - maybe it\'s not available in a repository?')

    local installPath = assert(Config.searchPaths[1])
    local baseName = Package.buildBaseName(package.name, package.version)
    local fileName
    local job

    if package.type == 'native' then
        fileName = FS.path(installPath, baseName)
        job = DownloadManager.startDownload(fileName, package.downloadUrl, true)
    else
        fileName = FS.path(installPath, baseName..'.zip')
        job = DownloadManager.startDownload(fileName, package.downloadUrl, false)
    end

    SuspendCoroTillJobIsDone(job)

    package.localFileName = fileName
    Package.mergePackages(package, LocalPackage.readLocalPackage(fileName))
    LocalPackage.setup(package)
end

function ChangeCoroFunctions.uninstall( change )
    -- TODO: Create job for this
    LocalPackage.remove(db, change.package)
end


-- Apply gathered changes.
-- TODO: This is an asynchronous operation and should therefore return a future
-- object, which can be used to query its completion status.
function PackageManager.applyChanges( changes )
    for _, change in ipairs(changes) do
        local coroFn = ChangeCoroFunctions[change.type]
        assert(coroFn, 'Unknown change type.')
        change.coro = coroutine.create(coroFn)
        ResumeCoroutineAndPropagateErrors(change.coro, change)
    end
end


return PackageManager
