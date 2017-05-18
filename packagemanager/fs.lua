local lfs = require 'lfs'
local cjson = require 'cjson'
local path = require 'path'


local FS = {}

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
                FS.recursiveDelete(path.join(filePath, entry))
            end
        end
    end
    return os.remove(filePath)
end

local function GetSourcePath( stackIndex )
    local info = debug.getinfo(stackIndex+1, 'S')
    if info and
       info.source and
       info.source:sub(1,1) == '@' then
        return info.source:sub(2)
    end
end

local SourceDirPattern = '^(.*)[/\\]'
local function GetSourceDir( stackIndex )
    local sourcePath = GetSourcePath(stackIndex+1)
    if sourcePath then
        return sourcePath:match(SourceDirPattern)
    end
end

--- Gives the current directory or a subpath thereof.
function FS.here( subPath )
    local sourceDir = GetSourceDir(2)
    if sourceDir then
        if subPath then
            return path.join(sourceDir, subPath)
        else
            return sourceDir
        end
    end
end


return FS
