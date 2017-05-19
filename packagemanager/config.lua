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

local Path = require 'path'
local FS = require 'packagemanager/fs'
local Misc = require 'packagemanager/misc'
local Version = require 'packagemanager/version'


local DefaultEnvironmentVariableValues
if Misc.operatingSystem == 'windows' then
    DefaultEnvironmentVariableValues = {}
else
    local home = assert(os.getenv('HOME'))
    DefaultEnvironmentVariableValues =
    {
        XDG_DATA_HOME   = Path.join(home, '.local/share'),
        XDG_CONFIG_HOME = Path.join(home, '.config'),
        XDG_CACHE_HOME  = Path.join(home, '.cache')
    }
end

local function GetEnvVar( name )
    return os.getenv(name) or DefaultEnvironmentVariableValues[name]
end

local function ReplaceEnvironmentVariables( str )
    for _, pattern in ipairs{'%$([%a_][%a%n_]+)', -- $FOO_BAR
                             '%${.-}',            -- ${FOO_BAR}
                             '%%.-%%'} do         -- %FOO_BAR%
        str = str:gsub(pattern, GetEnvVar)
    end
    return str
end

local function ExpandPathExpression( fileName )
    fileName = ReplaceEnvironmentVariables(fileName)
    fileName = fileName:gsub('~', os.getenv('HOME'))
    return fileName
end

local function ImportPath( fileName, config )
    fileName = ExpandPathExpression(fileName)
    if not Path.isabs(fileName) then
        fileName = Path.join(config.baseDir, fileName)
    end
    return fileName
end

local function ImportRequirement( requirement )
    return {packageName = requirement.packageName,
            versionRange = Version.parseVersionRange(requirement.versionRange)}
end

local function ExportRequirement( requirement )
    return {packageName = requirement.packageName,
            versionRange = tostring(requirement.versionRange)}
end

local function PassThrough( value )
    return value
end

local function CreateConfigDir()
    local expression
    if Misc.operatingSystem == 'windows' then
        expression = '%APPDATA%\\konstrukt'
    else
        expression = '$XDG_CONFIG_HOME/konstrukt'
    end
    local fileName = ExpandPathExpression(expression)
    assert(Path.mkdir(fileName))
    return expression, fileName
end

local function CreateCacheDir( name )
    local expression
    if Misc.operatingSystem == 'windows' then
        expression = '%LOCALAPPDATA%\\konstrukt\\'..name
    else
        expression = '$XDG_CACHE_HOME/konstrukt/'..name
    end
    local fileName = ExpandPathExpression(expression)
    assert(Path.mkdir(fileName))
    return expression, fileName
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
        default = nil,
        setup = function()
            local pathExpr = CreateCacheDir('packages')
            return {pathExpr}
        end,
        import = function( pathExpressions, config )
            local r = {}
            for i, pathExpression in ipairs(pathExpressions) do
                local path = ImportPath(pathExpression, config)
                assert(Path.isdir(path), path..' is not a directory')
                r[i] = path
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
        setup = function()
            return CreateCacheDir('repositories')
        end,
        import = ImportPath,
        export = PassThrough
    },

    documentationCacheDir =
    {
        default = nil,
        setup = function()
            return CreateCacheDir('documentation')
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
    assert(config.allowModifications, 'Modifications are not allowed.')
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

    local allowModifications = false
    if not fileName then
        allowModifications = true
        local _, configDir = CreateConfigDir()
        fileName = Path.join(configDir, 'config.json')
    end

    fileName = Path.abspath(fileName)
    local baseDir = Path.dirname(fileName)
    Config.fileName = fileName
    Config.baseDir = baseDir
    Config.dirty = false -- true if modifications were made and the config needs to be saved
    Config.allowModifications = allowModifications

    local source
    if Path.exists(fileName) then
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

    -- Run setup for missing values:
    for key, format in pairs(ConfigEntryFormat) do
        local sourceValue = source[key]
        if not sourceValue and format.setup then
            if not allowModifications then
                error(string.format('Config entry "%s" is not defined and setup can\'t be run as modifications are not allowed.', key))
            end
            SetEntryValue(Config, key, format.setup(Config))
        end
    end

    setmetatable(Config, ConfigMT)
end

function Config.save()
    if Config.dirty then
        assert(Config.allowModifications,
               'Modifications are not allowed.  (This should have been detected earlier.)')
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
