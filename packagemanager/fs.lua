local lfs = require 'lfs'
local cjson = require 'cjson'
local Path = require('packagemanager/path').native


local FS = {}

function FS.makeAbsolutePath( filePath, baseDir )
    if Path.isRelative(filePath) then
        baseDir = baseDir or FS.getCurrentDirectory()
        assert(Path.isAbsolute(baseDir))
        return Path.join(baseDir, filePath)
    else
        return filePath
    end
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

function FS.recursiveDelete( filePath )
    if lfs.symlinkattributes(filePath, 'mode') == 'directory' then
        for entry in lfs.dir(filePath) do
            if entry ~= '.' and
               entry ~= '..' then
                FS.recursiveDelete(Path.join(filePath, entry))
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
        return nil, 'File exists'
    else
        return path
    end
end

function FS.makeDirectoryPath( base, path )
    for seperatorPos in path:gmatch('()['..Path.directorySeparators..']') do
        local subPath = path:sub(1, seperatorPos-1)
        local result, errMsg = MakeDirIfNotExists(Path.join(base, subPath))
        if not result then
            return nil, errMsg
        end
    end
    return MakeDirIfNotExists(Path.join(base, path))
end

function FS.getCurrentDirectory()
    return assert(lfs.currentdir())
end

local function GetSourcePath( stackIndex )
    local info = debug.getinfo(stackIndex+1, 'S')
    if info and
       info.source and
       info.source:sub(1,1) == '@' then
        return info.source:sub(2)
    end
end

local SourceDirPattern = '^(.*)['..Path.directorySeparators..']'
local function GetSourceDir( stackIndex )
    local sourcePath = GetSourcePath(stackIndex+1)
    if sourcePath then
        return sourcePath:match(SourceDirPattern)
    end
end

--- Gives the current directory or a subpath thereof.
function FS.here( subPath )
    local path = GetSourceDir(2)
    if path then
        if subPath then
            return Path.join(path, subPath)
        else
            return path
        end
    end
end


return FS
