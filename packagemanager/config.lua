---
-- The config entries exist in two tables:
--
-- `Config.view` holds their in-programm representation and 
-- `Config.source` holds their serializable representation.
--
-- When running `Config.load` the entries are read from a JSON file and stored
-- directly in the `Config.source` table.  Then they're *imported* to the
-- `Config.view` table.
--
-- Creating or replacing entries works by exporting the given value to the
-- `Config.source` table - see `SetEntryValue`.
--
-- Their properties are defined in `ConfigEntryFormat`, look at that to learn
-- about their properties in detail.
--

local lfs = require 'lfs'
local FS = require 'packagemanager/fs'
local NativePath = require('packagemanager/path').native
local Version = require 'packagemanager/version'


local function ReplaceEnvironmentVariables( str )
    for _, pattern in ipairs{'%$(%w+)',   -- $FOO_BAR
                             '%${.-}',    -- ${FOO_BAR}
                             '%%.-%%'} do -- %FOO_BAR%
        str = str:gsub(pattern, os.getenv)
    end
    return str
end

local function ImportPath( path, config )
    path = ReplaceEnvironmentVariables(path)
    path = path:gsub('~', os.getenv('HOME'))
    if NativePath.isRelative(path) then
        path = NativePath.join(config.baseDir, path)
    end
    return path
end

local function ImportRequirement( requirement )
    return {packageName = requirement.packageName,
            versionRange = Version.parseVersionRange(requirement.versionRange)}
end

local function ExportRequirement( requirement )
    return {packageName = requirement.packageName,
            versionRange = tostring(requirement.versionRange)}
end

local function TestDirectoryPath( path )
    if lfs.attributes(path, 'mode') ~= 'directory' then
        error(path..' does not refer to a directory.')
    end
end

local function PassThrough( value )
    return value
end

---
-- This defines all valid config entries.
-- Each entry has the following properties:
--
-- - `default`: Provides an in-programm representation for entries that are not
-- present in the `Config.source` table.  Use this only when the value is not
-- used to create external dependencies such as files.
-- - `setup`: (optional) Function, which creates a reasonable default value,
-- stores it in `Config.source` and, most importantly, takes the required steps
-- to create any external dependencies.  This function is called by
-- `Config.setupEntry`, but only when `Config.source` does not have this entry
-- yet.
-- - `import`: Function, which converts serializable to the in-programm
-- representation.  The original value must not be modified.  This function can
-- and should raise an error when confronted with malformatted input.
-- - `export`: Function, which does the opposite of `import`.
--
local ConfigEntryFormat =
{
    searchPaths =
    {
        default = {},
        import = function( paths, config )
            local r = {}
            for i, path in ipairs(paths) do
                r[i] = ImportPath(path, config)
                TestDirectoryPath(r[i])
            end
            return r
        end,
        export = PassThrough
    },

    repositories =
    {
        default = {'http://konstrukt.henry4k.de/packages/index.json'},
        import = PassThrough,
        export = PassThrough
    },

    repositoryCacheDir =
    {
        default = nil,
        setup = function( config )
            local path = 'repositories'
            assert(FS.makeDirectoryPath(config.baseDir, path))
            return path
        end,
        import = ImportPath,
        export = PassThrough
    },

    documentationCacheDir =
    {
        default = nil,
        setup = function( config )
            local path = 'documentation'
            assert(FS.makeDirectoryPath(config.baseDir, path))
            return path
        end,
        import = ImportPath,
        export = PassThrough
    },

    requirements =
    {
        default = {},
        import = function( requirements, config )
            local r = {}
            for i, requirement in ipairs(requirements) do
                r[i] = ImportRequirement(requirement)
            end
            return r
        end,
        export = function( requirements, config )
            local r = {}
            for i, requirement in ipairs(requirements) do
                r[i] = ExportRequirement(requirement)
            end
            return r
        end
    },

    manager =
    {
        default = {packageName = 'packagemanager',
                   versionRange = Version.parseVersionRange('*')},
        import = ImportRequirement,
        export = ExportRequirement
    }
}

local function SetEntryValue( config, key, value )
    local format = assert(ConfigEntryFormat[key], 'Not a valid config entry.')
    local exportedValue = format.export(value, config)
    config.source[key] = exportedValue
    config.view[key] = format.import(exportedValue, config)
    config.dirty = true
end

local ConfigMT =
{
    __index = function( self, key )
        local format = assert(ConfigEntryFormat[key], 'Not a valid config entry.')
        local value = self.view[key]
        if value then
            return value
        elseif format.setup then
            value = format.setup(self)
            SetEntryValue(self, key, value)
        end
        return value or format.default
    end,

    __newindex = SetEntryValue
}

local Config = {}

function Config.load( fileName )
    setmetatable(Config, nil)
    assert(not Config.source, 'Reloading is not supported.')
    fileName = fileName or 'config.json'

    fileName = FS.makeAbsolutePath(fileName)
    local baseDir = NativePath.dirName(fileName)
    Config.fileName = fileName
    Config.baseDir = baseDir
    Config.dirty = false

    local source
    if FS.fileExists(fileName) then
        source = FS.readJsonFile(fileName)
    else
        source = {}
    end
    Config.source = source

    -- Import values from source, the json document, to the view table:
    local view = {}
    for key, value in pairs(source) do
        local format = ConfigEntryFormat[key]
        if format then
            view[key] = format.import(value, Config)
        end
    end
    Config.view = view

    setmetatable(Config, ConfigMT)
end

function Config.save()
    if Config.dirty then
        FS.writeJsonFile(Config.fileName, Config.source)
        Config.dirty = false
    end
end

setmetatable(Config,
{
    __index = function()
        error('Nothing to see here! Config has not been loaded yet.')
    end
})

return Config
