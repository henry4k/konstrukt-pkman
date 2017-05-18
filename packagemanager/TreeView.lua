local lfs   = require 'lfs'
local path  = require 'path'
local zip   = require 'brimworks.zip'
local FS    = require 'packagemanager/fs'
local Misc  = require 'packagemanager/misc'


-------- DirectoryView

local DirectoryView = {}
DirectoryView.__index = DirectoryView

function DirectoryView:_getAbsFilePath( filePath, createDir )
    filePath = path.normalize(filePath)
    assert(not filePath:match('^%.%.'..path.DIR_SEP),
           'File path may not leave the base directory.')
    if createDir then
        local dirName = path.dirname(filePath)
        if dirName ~= '.' then
            assert(FS.makeDirectoryPath(self._path, dirName))
        end
    end
    return path.join(self._path, filePath)
end

function DirectoryView:openFile( filePath, mode )
    local absFilePath = self:_getAbsFilePath(filePath, mode == 'w')
    return assert(io.open(absFilePath, mode..'b'))
end

-- - size (in bytes)
-- - modification (unix timestamp)
function DirectoryView:getFileAttributes( filePath )
    local absFilePath = self:_getAbsFilePath(filePath)
    return lfs.attributes(absFilePath)
end

function DirectoryView:eachFile()
    local prefix = self._path..path.DIR_SEP
    local function yieldTree( directory )
        for entry in lfs.dir(prefix..directory) do
            if entry ~= '.' and entry ~= '..' then
                local entryPath
                if directory == '' then
                    entryPath = entry
                else
                    entryPath = path.join(directory, entry)
                end
                coroutine.yield(entryPath)
                if lfs.attributes(prefix..entryPath, 'mode') == 'directory' then
                    yieldTree(entryPath)
                end
            end
        end
    end
    return coroutine.wrap(function() yieldTree('') end)
end

function DirectoryView:destroy()
    -- nothing to do here
end

local function CreateDirectoryView( path )
    return setmetatable({ _path = path }, DirectoryView)
end

-------- ZipFileStream

local ZipFileStream = {}
ZipFileStream.__index = ZipFileStream

function ZipFileStream:read( length )
    local bytes
    if type(length) == 'number' then
        bytes = length
    else
        if length == '*a' then
            bytes = self._size
            -- actually one would need to take the position into account
        else
            error(string.format('Read mode "%s" not supported.', length))
        end
    end
    return self._handle:read(bytes)
end

function ZipFileStream:lines()
    error('Line iterator is not implemented.')
end

function ZipFileStream:seek()
    error('Seeking is not supported.')
end

function ZipFileStream:close()
    self._handle:close()
    self._handle = nil
end

local function CreateZipFileStream( handle, size )
    return setmetatable({ _handle = handle,
                          _size = size }, ZipFileStream)
end

-------- ZipView

local ZipView = {}
ZipView.__index = ZipView

function ZipView:_getFileId( filePath )
    filePath = path.normalize(filePath)
    assert(not filePath:match('^%.%.[/\\]'),
           'File path may not leave the base directory.')
    local fileId = assert(self._fileMapping[filePath], 'No such file.')
    return fileId
end

function ZipView:openFile( filePath, mode )
    if mode == 'r' then
        local fileId = self:_getFileId(filePath)
        local handle = assert(self._zipFile:open(fileId))
        local size = assert(self._zipFile:stat(fileId).size)
        return CreateZipFileStream(handle, size)
    else
        error('Can\'t modify ZIP archives.')
    end
end

-- - size (in bytes)
-- - modification (unix timestamp)
function ZipView:getFileAttributes( filePath )
    local stat = self._zipFile:stat(self:_getFileId(filePath))
    return { size = stat.size,
             modification = stat.mtime }
end

function ZipView:eachFile()
    return pairs(self._fileMapping)
end

function ZipView:destroy()
    self._zipFile:close()
    self._zipFile = nil
end

local function IsDirectory( path )
    return path:match('[/\\]$')
end

local function CreateZipView( path )
    local zipFile = assert(zip.open(path))

    local fileMapping = {}
    for i = 1, zipFile:get_num_files() do
        local filePath = assert(zipFile:stat(i)).name
        if not IsDirectory(filePath) then
            local normalizedFilePath = path.normalize(filePath)
            fileMapping[normalizedFilePath] = i
        end
    end

    return setmetatable({ _zipFile = zipFile,
                          _fileMapping = fileMapping }, ZipView)
end


return function( path )
    if NativePath.extension(path) == 'zip' then
        return CreateZipView(path)
    else
        return CreateDirectoryView(path)
    end
end
