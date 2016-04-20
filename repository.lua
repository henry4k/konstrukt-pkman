local lfs = require 'lfs'
local semver = require 'semver'
local Network = require 'network'
local FS      = require 'fs'
local Version = require 'version'


local Repository = {}

local function BuildRepoDatabaseFileName( repoName )
    return FS.path('repositories', repoName..'.json')
end

function Repository.updateRepo( name, url )
    local fileName = BuildRepoDatabaseFileName(name)
    Network.downloadFile(fileName, url)
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

local function BuildDownloadUrl( baseUrl, packageName, version )
    return string.format('%s/%s.%s.zip', baseUrl, packageName, version)
end

function Repository.loadRepoDatabaseFromFile( fileName )
    local repoData = FS.readJsonFile(fileName)
    local baseUrl = assert(repoData.baseUrl)
    local db = assert(repoData.packages)

    for packageName, versions in pairs(db) do
        local reformattedVersions = {}
        for _, package in ipairs(versions) do
            assert(package.version)
            reformattedVersions[package.version] = package
            PreprocessLoadedPackageEntry(package, packageName)
            package.downloadUrl =
                BuildDownloadUrl(baseUrl, packageName, package.version)
        end
        db[packageName] = reformattedVersions
    end

    return db
end

function Repository.loadRepoDatabase( repoName )
    local fileName = BuildRepoDatabaseFileName(repoName)
    return Repository.loadRepoDatabaseFromFile(fileName)
end


return Repository
