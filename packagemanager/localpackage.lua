local lfs = require 'lfs'
local cjson = require 'cjson'
local semver = require 'semver'
local FS        = require 'packagemanager/fs'
local Zip       = require 'packagemanager/zip'
local Version   = require 'packagemanager/version'
local PackageIndex = require 'packagemanager/packageindex'
local Package   = require 'packagemanager/package'


local LocalPackage = {}

local function ExtractPackageMetadata( fileName )
    local fileType = lfs.attributes(fileName, 'mode')
    if not fileType then
        error('File not found.')
    elseif fileType == 'directory' then
        return assert(FS.readJsonFile(FS.path(fileName, 'meta.json')))
    else
        if fileName:match('%.zip$') then
            return cjson.decode(assert(Zip.readFile(fileName, 'meta.json')))
        else
            error('Not a package: '..fileName)
        end
    end
end

local function PreprocessMetaData( metadata )
    metadata.version = semver(metadata.version or 0)

    if not metadata.dependencies then
        metadata.dependencies = {}
    end

    for package, versionRange in pairs(metadata.dependencies) do
        assert(type(versionRange) == 'string')
        metadata.dependencies[package] =
            Version.parseVersionRange(versionRange)
    end
end

local LocalPackageMT = {}
function LocalPackageMT.__index( package, key )
    if not package._metadataLoaded then
        package._metadataLoaded = true
        local metadata = ExtractPackageMetadata(package.localFileName)
        PreprocessMetaData(metadata)
        Package.mergePackages(package, metadata)
        return package[key]
    end
end

function LocalPackage.readLocalPackage( fileName )
    local packageInfo = assert(FS.parsePackageFileName(fileName))
    local package =
    {
        name = packageInfo.package,
        version = packageInfo.version,
        localFileName = fileName,
        _metadataLoaded = false
    }
    return setmetatable(package, LocalPackageMT)
end

local function IsLocalPackage( fileName )
    local mode = lfs.attributes(fileName, 'mode')
    if mode == 'directory' then
        local metaFileName = FS.path(fileName, 'meta.json')
        return lfs.attributes(metaFileName, 'mode') == 'file'
    elseif mode == 'file' then
        return fileName:match('%.zip$')
    end
end

function LocalPackage.gatherInstalledPackages( index, searchPaths )
    local packages = {}
    for _, searchPath in ipairs(searchPaths) do
        for entry in lfs.dir(searchPath) do
            local fileName = FS.path(searchPath, entry)
            local fileInfo = FS.parsePackageFileName(fileName)
            if fileInfo and IsLocalPackage(fileName) then
                local baseName = Package.buildBaseName(fileInfo.package,
                                                       fileInfo.version)
                if not packages[baseName] then
                    packages[baseName] = LocalPackage.readLocalPackage(fileName)
                end
            end
        end
    end

    for _, package in pairs(packages) do
        PackageIndex.addPackage(index, package)
    end
end

function LocalPackage.remove( index, package )
    assert(package.localFileName, 'File name missing - maybe package is not an installed package?')
    assert(os.remove(package.localFileName))
    PackageIndex.removePackage(package)
end


return LocalPackage
