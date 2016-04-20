local lfs = require 'lfs'
local cjson = require 'cjson'
local semver = require 'semver'
local Misc = require 'Misc'
local FS = require 'fs'
local Zip = require 'zip'
local Version = require 'version'


local Package = {}

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
            print('Not a package: '..fileName)
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

function Package.mergePackages( destination, source )
    for key, sourceValue in pairs(source) do
        local destValue = destination[key]
        if destValue then
            local sourceValueType = type(sourceValue)
            local destValueType   = type(destValue)
            if destValueType ~= sourceValueType then
                error(string.format('Type mismatch while merging %s:  %s <> %s',
                                    key, destValueType, sourceValueType))
            end
            if destValueType == 'table' then
                if not Misc.tablesAreEqual(destValue, sourceValue) then
                    error(string.format('Tables of property %s are not equal.', key))
                end
            end
        else
            destination[key] = sourceValue
        end
    end
end

local LocalPackageMT = {}
function LocalPackageMT.__index( package, key )
    if not package._metadataLoaded then
        package._metadataLoaded = true
        local metadata = ExtractPackageMetadata(package.localFileName)
        PreprocessMetaData(metadata)
        Package.mergePackages(package, metadata)
    end
end

function Package.readLocalPackage( fileName )
    local packageInfo = assert(FS.parsePackageFileName(fileName))
    local package =
    {
        name = packageInfo.package,
        version = packageInfo.version or semver(0),
        localFileName = fileName,
        _metadataLoaded = false
    }
    return setmetatable(package, LocalPackageMT)
end


return Package
