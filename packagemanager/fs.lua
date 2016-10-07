local lfs = require 'lfs'
local cjson = require 'cjson'
local semver = require 'semver'
local Misc = require 'packagemanager/misc'


local FS = {}

FS.dirSep = package.config:sub(1,1)
if not FS.dirSep:match('[/\\]') then
    FS.dirSep = '/'
    io.stderr:write('Failed to get directory separator.  Assuming "/"')
end

function FS.path( ... )
    local elements = {...}
    for i = 2, #elements do
        assert(FS.isRelativePath(elements[i]))
    end
    return table.concat(elements, FS.dirSep)
end

function FS.isAbsolutePath( filePath )
    return filePath:match('^/') or filePath:match('^.:\\')
end

function FS.isRelativePath( filePath )
    return not FS.isAbsolutePath(filePath)
end

function FS.makeAbsolutePath( filePath, baseDir )
    if FS.isRelativePath(filePath) then
        baseDir = baseDir or FS.getCurrentDirectory()
        assert(FS.isAbsolutePath(baseDir))
        return FS.path(baseDir, filePath)
    else
        return filePath
    end
end

function FS.dirName( filePath )
    return filePath:match('^(.+)[/\\]') or '.'
end

function FS.baseName( filePath )
    return filePath:match('([^/\\]+)$')
end

function FS.extension( filePath )
    return filePath:match('%.([^./\\]+)$')
end

function FS.stripExtension( filePath )
    return filePath:match('(.+)%.[^./\\]*$') or filePath
end

function FS.fileExists( fileName )
    return lfs.attributes(fileName, 'mode') ~= nil
end

function FS.readFile( fileName )
    local file = assert(io.open(fileName, 'r'))
    local content = file:read('*a')
    file:close()
    return content
end

function FS.readJsonFile( fileName )
    return cjson.decode(FS.readFile(fileName))
end

function FS.writeFile( fileName, content )
    local file = assert(io.open(fileName, 'w'))
    file:write(content)
    file:close()
end

function FS.writeJsonFile( fileName, value )
    return FS.writeFile(fileName, cjson.encode(value))
end

function FS.parseFileName( fileName )
    local path, pathEnd = fileName:match('^(.*)[/\\]()')
    pathEnd = pathEnd or 1
    local extensionStart, extension = fileName:match('()%.([^.]*)$', pathEnd)
    extensionStart = extensionStart or 0
    local baseName = fileName:sub(pathEnd, extensionStart-1)
    return {path=path, baseName=baseName, extension=extension}
end

function FS.parsePackageFileName( fileName )
    local result, err = FS.parseFileName(fileName)
    if not result then
        return nil, err
    end

    local baseName = result.baseName
    if not baseName or #baseName == 0 then
        return nil, 'No base name.'
    end

    local package, packageEnd = baseName:match('^([^.]+)()')
    if not package then
        return nil, 'No package name.'
    end
    result.package = package

    local version = baseName:match('^%.(.+)', packageEnd)
    if version then
        local success, resultOrErr = pcall(semver, version)
        if not success then
            return nil, resultOrErr
        end
        result.version = resultOrErr
    end

    return result
end

function FS.recursiveDelete( filePath )
    if lfs.symlinkattributes(filePath, 'mode') == 'directory' then
        for entry in lfs.dir(filePath) do
            if entry ~= '.' and
               entry ~= '..' then
                FS.recursiveDelete(FS.path(filePath, entry))
            end
        end
    end
    return os.remove(filePath)
end

local function MakeDirIfNotExists( path )
    local mode = lfs.attributes(path, 'mode')
    if not mode then
        return lfs.mkdir(path)
    elseif mode ~= 'directory' then
        return false, 'File exists'
    else
        return true
    end
end

function FS.makeDirectoryPath( base, path )
    for seperatorPos in path:gmatch('()[/\\]') do
        local subPath = path:sub(1, seperatorPos-1)
        local success, errMsg = MakeDirIfNotExists(FS.path(base, subPath))
        if not success then
            return false, errMsg
        end
    end
    return MakeDirIfNotExists(FS.path(base, path))
end

function FS.changeDirectory( path )
    assert(lfs.chdir(path))
end

function FS.getCurrentDirectory()
    return assert(lfs.currentdir())
end


return FS
