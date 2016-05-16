local FS = require 'packagemanager/fs'
local Version = require 'packagemanager/version'


local Config = {}

local function ParseFileContent( baseDir, source, dest )
    dest.searchPaths = {}
    for i, searchPath in ipairs(source.searchPaths or {}) do
        dest.searchPaths[i] = FS.makeAbsolutePath(searchPath, baseDir)
    end

    dest.repositories = source.repositories or {}
    dest.repositoryCacheDir = FS.makeAbsolutePath(source.repositoryCacheDir or 'repositories', baseDir)

    dest.requirements = {}
    for _, requirementGroup in ipairs(source.requirements or {}) do
        local destGroup = {}
        for packageName, versionRangeExpr in pairs(requirementGroup) do
            local versionRange = Version.parseVersionRange(versionRangeExpr)
            destGroup[packageName] = versionRange
        end
        table.insert(dest.requirements, destGroup)
    end
end

function Config.load( fileName )
    fileName = FS.makeAbsolutePath(fileName)
    local baseDir = FS.dirName(fileName)
    Config.fileName = fileName
    Config.baseDir = baseDir
    Config.content = {}

    local fileContent = FS.readJsonFile(fileName)
    ParseFileContent(baseDir, fileContent, Config.content)

    setmetatable(Config, { __index = Config.content })
end

setmetatable(Config, { __index = function() error('Nothing to see here! Config has not been loaded yet.') end })

return Config
