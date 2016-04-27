local zip = require 'brimworks.zip'


local Zip = {}

function Zip.readFile( zipFileName, entryName )
    local zipFile, zipErr = zip.open(zipFileName)
    if not zipFile then
        return nil, zipErr
    end

    local fileStat, fileErr= zipFile:stat(entryName)
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


return Zip
