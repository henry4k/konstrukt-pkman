local FS = require 'packagemanager/fs'

local function GetSourcePath( stackIndex )
    local info = debug.getinfo(stackIndex+1, 'S')
    if info and
       info.source and
       info.source:sub(1,1) == '@' then
        return info.source:sub(2)
    end
end

local function GetSourceDir( stackIndex )
    local sourcePath = GetSourcePath(stackIndex+1)
    if sourcePath then
        return sourcePath:match('^(.*)[/\\]')
    end
end

--- Gives the current directory or a subpath thereof.
return function( subPath )
    local path = GetSourceDir(2)
    if path then
        if subPath then
            return string.format('%s%s%s', path, FS.dirSep, subPath)
        else
            return path
        end
    end
end
