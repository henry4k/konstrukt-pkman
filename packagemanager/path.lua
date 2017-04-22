local Misc = require 'packagemanager/misc'

---
-- @param[type=string] directorySeparators
-- First character is the default separator.
--
function Implement( directorySeparators )
    assert(#directorySeparators >= 1)
    local defaultDirectorySeparator = directorySeparators:sub(1,1)

    local module

    local function isRelative( filePath )
        return not module.isAbsolute(filePath)
    end

    local function join( ... )
        local elements = {...}
        for i = 2, #elements do
            assert(isRelative(elements[i]))
        end
        return table.concat(elements, defaultDirectorySeparator)
    end

    local dirNamePattern = '^(.+)['..directorySeparators..']'
    local function dirName( filePath )
        return filePath:match(dirNamePattern) or '.'
    end

    local baseNamePattern = '([^'..directorySeparators..']+)$'
    local function baseName( filePath )
        return filePath:match(baseNamePattern)
    end

    local extensionPattern = '%.([^.'..directorySeparators..']+)$'
    local function extension( filePath )
        return filePath:match(extensionPattern)
    end

    local stripExtensionPattern = '(.+)%.[^.'..directorySeparators..']*$'
    local function stripExtension( filePath )
        return filePath:match(stripExtensionPattern) or filePath
    end

    local dirSepPattern = '['..directorySeparators..']'
    local function normalizeDirSeps( filePath )
        return filePath:gsub(dirSepPattern, defaultDirectorySeparator)
    end

    local function convert( filePath, pathType )
        if pathType == module then
            return filePath
        else
            assert(isRelative(filePath), 'Can\'t convert absolute path.')
            return filePath:gsub(dirSepPattern, pathType.defaultDirectorySeparator)
        end
    end

    local elementPattern = '[^'..directorySeparators..']+'
    -- luacheck: push ignore 542
    local function canonicalize( filePath )
        local elements = {}
        for element in string.gmatch(filePath, elementPattern) do
            if element == '.' then
                -- ignore
            elseif element == '..' and
                #elements > 0 and
                elements[#elements] ~= '..' then
                table.remove(elements) -- pop last entry
            else
                table.insert(elements, element)
            end
        end
        return table.concat(elements, defaultDirectorySeparator)
    end
    -- luacheck: pop

    local function resolveRelative( filePath, baseFilePath )
        local relativeFilePath
        if baseFilePath then
            relativeFilePath = join(baseFilePath, filePath)
        else
            relativeFilePath = filePath
        end
        return canonicalize(relativeFilePath)
    end

    local function parseFileName( fileName )
        local path, pathEnd = fileName:match('^(.*)['..directorySeparators..']()')
        pathEnd = pathEnd or 1
        local extensionStart, extension = fileName:match('()%.([^.]*)$', pathEnd)
        extensionStart = extensionStart or 0
        local baseName = fileName:sub(pathEnd, extensionStart-1)
        return {path=path, baseName=baseName, extension=extension}
    end

    module = { directorySeparators = directorySeparators,
               defaultDirectorySeparator = defaultDirectorySeparator,
               isRelative = isRelative,
               join = join,
               dirName = dirName,
               baseName = baseName,
               extension = extension,
               stripExtension = stripExtension,
               normalizeDirSeps = normalizeDirSeps,
               convert = convert,
               canonicalize = canonicalize,
               resolveRelative = resolveRelative,
               parseFileName = parseFileName }
    return module
end

local windows = Implement('\\/')
local unix    = Implement('/')

function windows.isAbsolute( filePath )
    return filePath:match('^.:\\')
end

function unix.isAbsolute( filePath )
    return filePath:match('^/')
end

local native
if Misc.operatingSystem == 'windows' then
    native = windows
else
    native = unix
end

return { windows = windows,
         unix    = unix,
         native  = native }
