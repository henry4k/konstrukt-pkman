local lfs = require 'lfs'
local zip = require 'brimworks.zip'
local bit32 = require 'bit32'
local Misc = require 'packagemanager/misc'
local FS = require 'packagemanager/fs'


local Zip = {}

function Zip.readFile( zipFileName, entryName )
    local zipFile, zipErr = zip.open(zipFileName)
    if not zipFile then
        return nil, zipErr
    end

    local fileStat, fileErr = zipFile:stat(entryName)
    if not fileStat then
        zipFile:close()
        return nil, fileErr
    end

    local fileSize = fileStat.size
    local file = assert(zipFile:open(entryName))

    local content = file:read(fileSize)

    file:close()
    zipFile:close()
    return content
end

local function IsDirectory( name )
    return name:sub(-1) == FS.dirSep
end

local function ExtractDirectory( stat, destination )
    assert(stat.size == 0, 'Size of a directory entry should be zero.')
    local dirName = stat.name:sub(1, -2) -- remove directory separator at the end
    assert(FS.makeDirectoryPath(destination, dirName))
end

local function ExtractFile( stat, destination, zipFile, i )
    local entryDirName = FS.dirName(stat.name)
    if entryDirName then
        assert(FS.makeDirectoryPath(destination, entryDirName))
    end

    local destFileName = FS.path(destination, stat.name)
    local sourceFile = assert(zipFile:open(i))
    local destFile = assert(io.open(destFileName, 'wb'))
    Misc.writeFile(destFile, sourceFile)
    sourceFile:close()
    destFile:close()

    if Misc.operatingSystem == 'unix' then
        -- Test if executable bit is set for the user:
        local attributes = zipFile:get_external_attributes(i)
        if bit32.btest(attributes, 2^22) then
            os.execute(string.format('chmod +x "%s"', destFileName))
        end
    end
end

function Zip.unpack( zipFileName, destination )
    local zipFile = assert(zip.open(zipFileName))
    for i = 1, zipFile:get_num_files() do
        local stat = assert(zipFile:stat(i))
        stat.name = stat.name:gsub('[/\\]', FS.dirSep) -- normalize directory separators
        if IsDirectory(stat.name) then
            ExtractDirectory(stat, destination)
        else
            ExtractFile(stat, destination, zipFile, i)
        end
    end
    zipFile:close()
end


return Zip
