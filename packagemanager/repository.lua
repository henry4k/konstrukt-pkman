local semver = require 'semver'
local Network = require 'packagemanager/network'
local FS      = require 'packagemanager/fs'
local Version = require 'packagemanager/version'
local Package = require 'packagemanager/package'


local Repository = {}

local function BuildRepoIndexFileName( repoName )
    return FS.path('repositories', repoName..'.json')
end

function Repository.updateIndex( name, url, downloadEventHandler )
    local fileName = BuildRepoIndexFileName(name)
    Network.downloadFile(fileName, url, downloadEventHandler)
end

local function PreprocessLoadedPackageEntry( package, packageName )
    package.name = packageName
    package.version = semver(assert(package.version))
    for dependency, versionRange in pairs(assert(package.dependencies)) do
        assert(type(dependency) == 'string')
        assert(type(versionRange) == 'string')
        package.dependencies[dependency] =
            Version.parseVersionRange(versionRange)
    end
end

local function BuildPackageDownloadUrl( baseUrl, packageName, version )
    return string.format('%s/%s.%s.zip', baseUrl, packageName, version)
end

function Repository.loadIndexFromFile( fileName )
    local repoData = FS.readJsonFile(fileName)
    local baseUrl = assert(repoData.baseUrl)
    local index = assert(repoData.packages)

    for packageName, versions in pairs(index) do
        local reformattedVersions = {}
        for _, package in ipairs(versions) do
            assert(package.version)
            reformattedVersions[package.version] = package
            PreprocessLoadedPackageEntry(package, packageName)
            package.downloadUrl =
                BuildPackageDownloadUrl(baseUrl, packageName, package.version)
        end
        index[packageName] = reformattedVersions
    end

    return index
end

function Repository.loadIndex( repoName )
    local fileName = BuildRepoIndexFileName(repoName)
    return Repository.loadIndexFromFile(fileName)
end

local function AddPackageToRepoData( repoData, package )
    local versions = repoData.packages[package.name]
    if not versions then
        versions = {}
        repoData.packages[package.name] = versions
    end

    local preparedPackage = {}
    preparedPackage.version = tostring(package.version)
    if package.dependencies then
        local preparedDependencies = {}
        for packageName, versionRange in pairs(package.dependencies) do
            preparedDependencies[packageName] = tostring(versionRange)
        end
        preparedPackage.dependencies = preparedDependencies
    end
    table.insert(versions, preparedPackage)
end

function Repository.saveIndexToFile( index, fileName, baseUrl )
    local repoData =
    {
        baseUrl = baseUrl,
        packages = {}
    }
    for _, versions in pairs(index) do
        for _, package in pairs(versions) do
            AddPackageToRepoData(repoData, package)
        end
    end
    FS.writeJsonFile(fileName, repoData)
end

function Repository.installPackage( package, installPath, downloadEventHandler )
    assert(package.downloadUrl, 'Package misses a download URL - maybe it\'s not available in a repository?')
    local baseName = Package.buildBaseName(package.name, package.version)
    local fileName = FS.path(installPath, baseName..'.zip')
    Network.downloadFile(fileName, package.downloadUrl, downloadEventHandler)
    package.localFileName = fileName
end


return Repository
