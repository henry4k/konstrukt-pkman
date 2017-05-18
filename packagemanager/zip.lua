local path = require 'path'
local zip = require 'brimworks.zip'
local bit32 = require 'bit32'
local Misc = require 'packagemanager/misc'


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
    return name:match('[/\\]$')
end

local function ExtractDirectory( stat, destination )
    assert(stat.size == 0, 'Size of a directory entry should be zero.')
    local dirName = path.remove_dir_end(stat.name)
    assert(path.mkdir(path.join(destination, dirName)))
end

local function ExtractFile( stat, destination, zipFile, i )
    local entryDirName = path.dirname(stat.name)
    if entryDirName then
        assert(path.mkdir(path.join(destination, entryDirName)))
    end

    local nativeName = path.normalize(stat.name)
    local destFileName = path.join(destination, nativeName)
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
        if IsDirectory(stat.name) then
            ExtractDirectory(stat, destination)
        else
            ExtractFile(stat, destination, zipFile, i)
        end
    end
    zipFile:close()
end


return Zip
