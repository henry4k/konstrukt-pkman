local lfs = require 'lfs'
local escapeUrl = require('socket.url').escape
local semver = require 'semver'
local LocalPackage = require 'packagemanager/localpackage'
local DownloadManager = require 'packagemanager/downloadmanager'
local FS           = require 'packagemanager/fs'
local Version      = require 'packagemanager/version'
local Package      = require 'packagemanager/package'
local Config       = require 'packagemanager/config'
local PackageDB    = require 'packagemanager/packagedb'


local Repository = {}

local function BuildRepoIndexFileName( url )
    return FS.path(Config.repositoryCacheDir, escapeUrl(url)..'.json')
end

function Repository.removeUnusedIndices()
    local usedIndexFileNameSet = {}
    for _, url in ipairs(Config.repositories) do
        usedIndexFileNameSet[BuildRepoIndexFileName(url)] = true
    end

    for entry in lfs.dir(Config.repositoryCacheDir) do
        local entryPath = FS.path(Config.repositoryCacheDir, entry)
        if not usedIndexFileNameSet[entryPath] then
            os.remove(entryPath)
        end
    end
end

function Repository.updateIndex( url )
    local fileName = BuildRepoIndexFileName(url)
    return DownloadManager.createDownload(url, fileName)
end

local function PreprocessLoadedPackageEntry( package, packageName )
    package.name = packageName
    package.version = semver(assert(package.version))
    if package.dependencies then
        for dependency, versionRange in pairs(assert(package.dependencies)) do
            assert(type(dependency) == 'string')
            assert(type(versionRange) == 'string')
            package.dependencies[dependency] =
                Version.parseVersionRange(versionRange)
        end
    end
    for name, version in pairs(package.provides or {}) do
        assert(type(name) == 'string')
        assert(type(version) == 'string')
        package.provides[name] = semver(version)
    end
end

local function BuildPackageDownloadUrl( baseUrl, packageName, version )
    return string.format('%s/%s.%s.zip', baseUrl, packageName, tostring(version))
end

function Repository.loadIndexFromFile( db, fileName )
    local repoData = FS.readJsonFile(fileName)
    local baseUrl = assert(repoData.baseUrl)

    for packageName, versions in pairs(repoData.packages) do
        for _, package in ipairs(versions) do
            assert(package.version)
            assert(package.type)
            PreprocessLoadedPackageEntry(package, packageName)
            package.downloadUrl =
                BuildPackageDownloadUrl(baseUrl, packageName, package.version)
            PackageDB.addPackage(db, package)
        end
    end
end

function Repository.loadIndex( db, url )
    local fileName = BuildRepoIndexFileName(url)
    if FS.fileExists(fileName) then
        return Repository.loadIndexFromFile(db, fileName)
    else
        return nil, url..' has not been downloaded yet.'
    end
end

local function AddPackageToRepoData( repoData, package )
    local versions = repoData.packages[package.name]
    if not versions then
        versions = {}
        repoData.packages[package.name] = versions
    end

    local preparedPackage = {}
    preparedPackage.type = package.type
    preparedPackage.version = tostring(package.version)

    if package.dependencies then
        local preparedDependencies = {}
        for packageName, versionRange in pairs(package.dependencies) do
            preparedDependencies[packageName] = tostring(versionRange)
        end
        preparedPackage.dependencies = preparedDependencies
    end

    if package.provides then
        local preparedProvides = {}
        for name, version in pairs(package.provides) do
            preparedProvides[name] = tostring(version)
        end
        preparedPackage.provides = preparedProvides
    end

    table.insert(versions, preparedPackage)
end

function Repository.saveIndexToFile( db, fileName, baseUrl )
    local repoData =
    {
        baseUrl = baseUrl,
        packages = {}
    }
    for package in PackageDB.packages(db) do
        AddPackageToRepoData(repoData, package)
    end
    FS.writeJsonFile(fileName, repoData)
end


return Repository
