local semver = require 'semver'
local LocalPackage = require 'packagemanager/localpackage'
local Network      = require 'packagemanager/network'
local FS           = require 'packagemanager/fs'
local Version      = require 'packagemanager/version'
local Package      = require 'packagemanager/package'
local Config       = require 'packagemanager/config'
local PackageDB    = require 'packagemanager/packagedb'


local Repository = {}

local function BuildRepoIndexFileName( repoName )
    return FS.path(Config.repositoryCacheDir, repoName..'.json')
end

function Repository.updateIndex( name, url, downloadEventHandler )
    local fileName = BuildRepoIndexFileName(name)
    Network.downloadFile(fileName, url, downloadEventHandler)
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

function Repository.loadIndex( db, repoName )
    local fileName = BuildRepoIndexFileName(repoName)
    return Repository.loadIndexFromFile(db, fileName)
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

function Repository.installPackage( package, installPath, downloadEventHandler )
    assert(package.downloadUrl, 'Package misses a download URL - maybe it\'s not available in a repository?')

    local baseName = Package.buildBaseName(package.name, package.version)
    local fileName

    if package.type == 'regular' or
       package.type == 'scenario' then
        fileName = FS.path(installPath, baseName..'.zip')
        Network.downloadFile(fileName,
                             package.downloadUrl,
                             downloadEventHandler)
    else
        fileName = FS.path(installPath, baseName)
        Network.downloadAndUnpackZipFile(fileName,
                                         package.downloadUrl,
                                         downloadEventHandler)
    end

    package.localFileName = fileName
    Package.mergePackages(package, LocalPackage.readLocalPackage(fileName))
    LocalPackage.setup(package)
end


return Repository
