local lfs = require 'lfs'
local http = require 'socket.http'
local Zip = require 'packagemanager/zip'


local Network = {}

local MonthNameIndexMap =
{
    Jan = 1,
    Feb = 2,
    Mar = 3,
    Apr = 4,
    May = 5,
    Jun = 6,
    Jul = 7,
    Aug = 8,
    Sep = 9,
    Oct = 10,
    Nov = 11,
    Dec = 12
}

local function GetUtcOffset()
    local localTime = os.time()
    local utcTime   = os.time(os.date("!*t"))
    return localTime - utcTime
end

local function ParseHttpDate( date )
    assert(date)
    -- Source: https://stackoverflow.com/questions/4105012/convert-a-string-date-to-a-timestamp
    local day, month, year, hour, min, sec =
        date:match('%a+, (%d+) (%a+) (%d+) (%d+):(%d+):(%d+) GMT')
    assert(day, 'Parsing failed.')
    month = MonthNameIndexMap[month] -- convert month name to index
    local utcTime =
        os.time{day=day, month=month, year=year, hour=hour, min=min, sec=sec}
    return utcTime + GetUtcOffset()
end

local function GetResourceHeaders( url )
    -- luacheck: ignore
    local response, statusCode, headers =
        assert(http.request{method='HEAD', url=url})
    if statusCode < 200 or statusCode >= 300 then
        error(string.format('%s is not available: %d', url, statusCode))
    end
    return headers
end

local function FileProcessSink( file, eventHandler )
    local bytesWritten = 0
    return function( chunk )
        if chunk then
            bytesWritten = bytesWritten + #chunk
            eventHandler:onDownloadProgress(bytesWritten)
            return file:write(chunk)
        else
            file:close()
            return 1
        end
    end
end

function Network.downloadFile( fileName, url, eventHandler )
    -- 1. obtain file modification timestamp
    local fileModificationTime = lfs.attributes(fileName, 'modification')
    -- 2. HEAD request to obtain url modification timestamp
    local resourceHeaders = GetResourceHeaders(url)
    local resourceModificationTime
    if resourceHeaders['last-modified'] then
        resourceModificationTime =
            ParseHttpDate(resourceHeaders['last-modified'])
    end
    -- 3. download url to file
    if not fileModificationTime or
       not resourceModificationTime or
       resourceModificationTime > fileModificationTime then
        local file = assert(io.open(fileName, 'w'))
        local sink = FileProcessSink(file, eventHandler)
        local size = tonumber(resourceHeaders['content-length'])
        eventHandler:onDownloadBegin(fileName, url, size)
        assert(http.request{url=url, sink=sink})
        eventHandler:onDownloadEnd()
    end
end

function Network.downloadAndUnpackZipFile( directory, url, eventHandler )
    local tmpFileName = directory..'.zip.tmp'
    Network.downloadFile(tmpFileName, url, eventHandler)
    assert(lfs.mkdir(directory))
    Zip.unpack(tmpFileName, directory)
    assert(os.remove(tmpFileName))
end


return Network
