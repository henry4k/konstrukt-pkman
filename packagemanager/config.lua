local FS = require 'packagemanager/fs'
local Version = require 'packagemanager/version'


local Config = {}

local ConfigMT = {}

function ConfigMT:__index( key )
    return Config.content[key]
end

function ConfigMT:__newindex( key, value )
    Config.content[key] = value
    Config.dirty = true
end

local function JsonToInternal( json, internal )
    local baseDir = Config.baseDir
    local fileName = Config.fileName

    internal.searchPaths = json.searchPaths or {}
    internal.repositories = json.repositories or {}
    internal.repositoryCacheDir = json.repositoryCacheDir or 'repositories'
    internal.requirements = {}
    for _, requirement in ipairs(json.requirements or {}) do
        local versionRangeExpr = requirement.versionRange
        local versionRange = Version.parseVersionRange(versionRangeExpr)
        table.insert(internal.requirements,
                     { packageName = requirement.packageName,
                       versionRange = versionRange })
    end
end

local function InternalToJson( internal, json )
    json.searchPaths = internal.searchPaths
    json.repositories = internal.repositories
    json.repositoryCacheDir = internal.repositoryCacheDir
    json.requirements = {}
    for _, requirement in ipairs(internal.requirements) do
        table.insert(json.requirements,
                     { packageName = requirement.packageName,
                       versionRange = tostring(requirement.versionRange) })
    end
end

function Config.load( fileName )
    fileName = fileName or 'config.json'

    setmetatable(Config, nil)
    assert(not Config.content, 'Reloading is not supported.')

    fileName = FS.makeAbsolutePath(fileName)
    local baseDir = FS.dirName(fileName)
    Config.fileName = fileName
    Config.baseDir = baseDir
    Config.dirty = false

    local json = {}
    if FS.fileExists(fileName) then
        json = FS.readJsonFile(fileName)
    end
    Config.content = {}
    JsonToInternal(json, Config.content)

    setmetatable(Config, ConfigMT)
    FS.changeDirectory(baseDir)
end

function Config.save( fileName )
    fileName = fileName or Config.fileName
    if fileName ~= Config.fileName or
       Config.dirty then
        local json = {}
        InternalToJson(Config.content, json)
        FS.writeJsonFile(fileName, json)
    end
end

setmetatable(Config, { __index = function() error('Nothing to see here! Config has not been loaded yet.') end })

return Config
