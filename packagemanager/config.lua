local FS = require 'packagemanager/fs'
local Version = require 'packagemanager/version'


local Config = {}

local ConfigMT = {}

function ConfigMT.__index( key )
    return Config.content[key]
end

function ConfigMT.__newindex( key, value )
    Config.content[key] = value
end

local function ReadConfig( fileName )
    local baseDir = Config.baseDir
    local fileName = Config.fileName
    local src = FS.readJsonFile(fileName)
    local dst = {}

    dst.searchPaths = {}
    for i, searchPath in ipairs(src.searchPaths or {}) do
        dst.searchPaths[i] = FS.makeAbsolutePath(searchPath, baseDir)
    end

    dst.repositories = src.repositories or {}
    dst.repositoryCacheDir = FS.makeAbsolutePath(src.repositoryCacheDir or 'repositories', baseDir)

    dst.requirements = {}
    for groupName, group in pairs(src.requirements or {}) do
        for packageName, versionRangeExpr in pairs(group) do
            local versionRange = Version.parseVersionRange(versionRangeExpr)
            group[packageName] = versionRange
        end
        dst.requirements[groupName] = group
    end

    Config.content = dst
end

function Config.load( fileName )
    assert(not Config.content, 'Reloading not supported.')

    fileName = FS.makeAbsolutePath(fileName)
    local baseDir = FS.dirName(fileName)
    Config.fileName = fileName
    Config.baseDir = baseDir

    ReadConfig(fileName)

    setmetatable(Config, ConfigMT)
end

function Config.save( fileName )
    fileName = fileName or Config.fileName
    local src = Config.content
    local dst = {}

    error('Not implemented yet.')
end

setmetatable(Config, { __index = function() error('Nothing to see here! Config has not been loaded yet.') end })

return Config
