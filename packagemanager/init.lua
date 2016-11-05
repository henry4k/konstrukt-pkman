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
    local tasks = {}
    for name, url in pairs(Config.repositories) do
        local task = Repository.updateIndex(name, url)
        table.insert(tasks, task)
    end
    return tasks -- TODO: And then?
end


-- Read/edit requirements {{{1

function PackageManager.getRequirements()
    return Config.requirements
end

function PackageManager.setRequirements( requirements )
    Config.requirements = requirements
end


-- Query database {{{1

function PackageManager.searchWithQueryString( query )
    local comparators = {}
    local options = {}

    if query and #query > 0 then
        comparators.name = function( value )
            return value:match(query)
        end
    end

    return PackageManager.search(comparators, options)
end

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
    return PackageDB.gatherPackages(db, comparators)
end


-- Query and apply changes {{{1

-- Build change list.
--
-- @return
-- A list that contains the gathered changes or `nil` together with an error
-- message if something went wrong.
-- Each change looks like this: `{ type = [install, uninstall], package = ... }`
function PackageManager.gatherChanges()
    local errors = {}
    local neededPackages = {}
    for _, requirement in ipairs(Config.requirements) do
        local dependencies = {}
        dependencies[requirement.packageName] = requirement.versionRange
        local success, packagesOrErr = pcall(Dependency.resolve, db, dependencies)
        if success then
            for _, package in pairs(packagesOrErr) do
                if not package.localFileName and not package.virtual then
                    neededPackages[package] = true
                end
            end
        else
            table.insert(errors, packagesOrErr)
        end
    end

    local changes = {}
    for package, _ in pairs(neededPackages) do
        table.insert(changes, { type = 'install', package = package })
    end

    -- TODO: Gather obsolete packages too!

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
        downloadTask = DownloadManager.startDownload(fileName, package.downloadUrl, true)
    else
        fileName = FS.path(installPath, baseName..'.zip')
        downloadTask = DownloadManager.startDownload(fileName, package.downloadUrl, false)
    end

    task.downloadTask = downloadTask
    assert(downloadTask:wait())

    package.localFileName = fileName
    Package.mergePackages(package, LocalPackage.readLocalPackage(fileName))
    LocalPackage.setup(package)
end

function ChangeTaskFunctions.uninstall( task, change )
    -- TODO: Create task for this
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
