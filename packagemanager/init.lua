-- vim: set foldmethod=marker:
-- High level interface to the package manager:

local Config = require 'packagemanager/config'
local Repository = require 'packagemanager/repository'
local DownloadManager = require 'packagemanager/downloadmanager'
local LocalPackage = require 'packagemanager/localpackage'
local Dependency = require 'packagemanager/dependency'
local PackageDB = require 'packagemanager/packagedb'
local Package = require 'packagemanager/package'
local Version = require 'packagemanager/version'
local Task = require 'packagemanager/Task'
local FS = require 'packagemanager/fs'


local PackageManager = {}
local db

-- General stuff {{{1

function PackageManager.initialize( configFileName )
    Config.load(configFileName)
    PackageManager.buildPackageDB()
end

function PackageManager.finalize()
    DownloadManager.finalize()
    Config.save()
end

function PackageManager.update()
    DownloadManager.update()
end


-- Read/edit repositories {{{1

function PackageManager.getRepositories()
    return Config.repositories
end

function PackageManager.setRepositories( repositories )
    -- TODO: Check format
    Config.repositories = repositories
end

--- Remove unused repository indices and update/download changed or new ones.
-- @return download tasks
function PackageManager.updateRepositoryIndices()
    Repository.removeUnusedIndices()

    local tasks = {}
    for _, url in ipairs(Config.repositories) do
        local task = Repository.updateIndex(url)
        table.insert(tasks, task)
    end

    return tasks
end

--- Rebuild package database.
--
-- @param[type=table] options
-- - localPackages: use search paths to find locally available packages
-- - remotePackages: read package information from repository indices
function PackageManager.buildPackageDB( options )
    options = options or {localPackages=true, remotePackages=true}
    db = PackageDB.create()
    if options.localPackages then
        LocalPackage.gatherInstalledPackages(db, Config.searchPaths)
    end
    if options.remotePackages then
        for _, url in pairs(Config.repositories) do
            Repository.loadIndex(db, url)
        end
    end
end


-- Read/edit requirements {{{1

function PackageManager.getRequirements()
    return Config.requirements
end

function PackageManager.setRequirements( requirements )
    -- TODO: Check format
    Config.requirements = requirements
end


-- Query database {{{1

---
-- @param[type=table] comparators
-- Each key value pair is a comparator.
-- The key specifies the package property name and the value is either a constant value or a comparator function.
-- They act as a filter.
--
-- @return
-- A list of packages in no particular order.
function PackageManager.search( comparators )
    return PackageDB.gatherPackages(db, comparators)
end

---
-- @see PackageManager.search
function PackageManager.searchWithQueryString( query )
    local comparators = {}

    if query and #query > 0 then
        comparators.name = function( value )
            return value:match(query)
        end
    end

    return PackageManager.search(comparators)
end


-- Query and apply changes {{{1

function PackageManager.gatherRequiredPackages()
    local errors = {}
    local requiredPackages = {}
    for _, requirement in ipairs(Config.requirements) do
        local dependencies = {}
        dependencies[requirement.packageName] = requirement.versionRange
        local success, packagesOrErr = pcall(Dependency.resolve, db, dependencies)
        if success then
            for _, package in pairs(packagesOrErr) do
                if not package.virtual then
                    requiredPackages[package] = true
                end
            end
        else
            table.insert(errors, packagesOrErr)
        end
    end
    return requiredPackages, errors
end

local function NotNil( value )
    return value ~= nil
end

-- Build change list.
--
-- @return
-- A list that contains the gathered changes or `nil` together with an error
-- message if something went wrong.
-- Each change looks like this: `{ type = [install, uninstall], package = ... }`
function PackageManager.gatherChanges()
    local requiredPackages, errors = PackageManager.gatherRequiredPackages()

    local installedPackages = PackageManager.search{ localFileName = NotNil }

    local changes = {}

    for package, _ in pairs(requiredPackages) do
        if not package.localFileName then
            table.insert(changes, { type = 'install', package = package })
        end
    end

    for _, package in ipairs(installedPackages) do
        if not requiredPackages[package] then
            table.insert(changes, { type = 'uninstall', package = package })
        end
    end

    return changes, errors
end

local ChangeTaskFunctions = {}
function ChangeTaskFunctions.install( task, change )
    local package = change.package
    assert(package.downloadUrl, 'Package misses a download URL - maybe it\'s not available in a repository?')

    local installPath = assert(Config.searchPaths[1])
    local baseName = Package.buildBaseName(package.name, package.version)
    local fileName
    local downloadTask

    if package.type == 'native' then
        fileName = FS.path(installPath, baseName)
        downloadTask = DownloadManager.createDownload(package.downloadUrl, fileName, true)
    else
        fileName = FS.path(installPath, baseName..'.zip')
        downloadTask = DownloadManager.createDownload(package.downloadUrl, fileName, false)
    end

    downloadTask.events.downloadStarted = function()
        task:fireEvent('downloadStarted')
    end
    downloadTask:start()
    task.downloadTask = downloadTask
    assert(downloadTask:wait())

    package.localFileName = fileName
    Package.mergePackages(package, LocalPackage.readLocalPackage(fileName))
    LocalPackage.setup(package)
end

function ChangeTaskFunctions.uninstall( task, change )
    LocalPackage.remove(db, change.package)
end

-- Apply gathered changes.
-- As this is an asynchronous operation, it returns a task for each change.
-- I. e. it returns a map, where each key-value pair is a change-task pair.
function PackageManager.applyChanges( changes )
    local tasks = {}
    for _, change in ipairs(changes) do
        local fn = ChangeTaskFunctions[change.type]
        assert(fn, 'Unknown change type.')
        local task = Task.fromFunction(fn, change)
        tasks[change] = task
    end
    return tasks
end


-- Launch scenarios {{{1

function PackageManager.launchScenario( package )
    assert(package.type == 'scenario', 'Package is not a scenario.')

    local dependencies = {}
    dependencies[package.name] = Version.versionToVersionRange(package.version)
    local packages = Dependency.resolve(db, dependencies)

    local engine
    for _, package in ipairs(packages) do
        assert(package.localFileName, package.name..' is not installed.')
        if package.type == 'engine' then
            assert(not engine, 'Multiple engine packages detected!')
            engine = package
        end
    end
    assert(engine, 'Scenario has no engine as (indirect) dependency.')

    print('TODO: launch '..engine.localFileName)
end


return PackageManager
