local lfs = require 'lfs'
local http = require 'socket.http'


local network = {}

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
    local response, statusCode, headers =
        assert(http.request{method='HEAD', url=url})
    return headers
end

local function FileProcessSink( file, totalBytes )
    local bytesWritten = 0
    io.stdout:write('0%')
    return function( chunk )
        if chunk then
            bytesWritten = bytesWritten + #chunk
            local fraction = bytesWritten / totalBytes
            io.stdout:write(string.format('\r%d%%', fraction*100))
            return file:write(chunk)
        else
            io.stdout:write('\n')
            file:close()
            return 1
        end
    end
end

-- Also use this to update package lists
function network.downloadFile( fileName, url )
    -- 1. obtain file modification timestamp
    local fileModificationTime = lfs.attributes(fileName, 'modification')
    -- 2. HEAD request to obtain url modification timestamp
    local resourceHeaders = GetResourceHeaders(url)
    local resourceModificationTime =
        ParseHttpDate(resourceHeaders['last-modified'])
    -- 3. download url to file (downloadFile)
    if not fileModificationTime or
       resourceModificationTime > fileModificationTime then
        print(string.format('Downloading %s from %s ...', fileName, url))
        local file = assert(io.open(fileName, 'w'))
        local sink = FileProcessSink(file, resourceHeaders['content-length'])
        assert(http.request{url=url, sink=sink})
    else
        print(string.format('%s is up to date.', fileName))
    end
end


return network
