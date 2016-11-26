local lfs = require 'lfs'
local http = require 'socket.http'
local https = require 'ssl.https'
local Zip = require 'packagemanager/zip'


local Network = {}

local MaxRedirections = 1

local function HttpHttpsRequest( options )
    if options.url:match('^https') then
       options.protocol = 'sslv23'
       options.options = 'all'
        -- TODO: Certificate validation is currently disabled, as I'm not sure
        --       where/how to store the certificates yet.
        --options.verify = {'peer', 'client_once'}
        --options.capath = ...
        --options.cafile = ...
        return https.request(options)
    else
        return http.request(options)
    end
end

local function RequestWithRedirection( options )
    options.redirect = false
    options.redirectionCount = options.redirectionCount or 0
    assert(options.redirectionCount <= MaxRedirections, 'Too many redirections.')
    local result, code, headers, status = HttpHttpsRequest(options)
    if result and code >= 300 and code < 400 then
        options.url = assert(headers.location, 'Location header missing - can\'t redirect.')
        options.redirectionCount = options.redirectionCount + 1
        return RequestWithRedirection(options)
    end
    return result, code, headers, status
end

Network.request = RequestWithRedirection

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

local function GetRawResourceHeaders( url )
    -- luacheck: ignore
    local response, statusCode, headers =
        assert(Network.request{method='HEAD', url=url})
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

function Network.getResourceHeaders( url )
    local rawHeaders = GetRawResourceHeaders(url)
    local headers = {}
    if rawHeaders['last-modified'] then
        headers.modificationTime = ParseHttpDate(rawHeaders['last-modified'])
    end
    if rawHeaders['content-length'] then
        headers.size = tonumber(rawHeaders['content-length'])
    end
    return headers
end

function Network.downloadFile( url, fileName, eventHandler )
    -- 1. obtain file modification timestamp
    local fileModificationTime = lfs.attributes(fileName, 'modification')
    -- 2. HEAD request to obtain url modification timestamp
    local resourceHeaders = Network.getResourceHeaders(url)
    local resourceModificationTime = resourceHeaders.modificationTime
    -- 3. download url to file
    if not fileModificationTime or
       not resourceModificationTime or
       resourceModificationTime > fileModificationTime then
        local file = assert(io.open(fileName, 'wb'))
        local sink = FileProcessSink(file, eventHandler)
        local size = resourceHeaders.size
        eventHandler:onDownloadBegin(fileName, url, size)
        assert(Network.request{url=url, sink=sink})
        eventHandler:onDownloadEnd()
    end
end

function Network.downloadAndUnpackZipFile( url, directory, eventHandler )
    local tmpFileName = directory..'.zip.tmp'
    Network.downloadFile(tmpFileName, url, eventHandler)
    assert(lfs.mkdir(directory))
    Zip.unpack(tmpFileName, directory)
    assert(os.remove(tmpFileName))
end


return Network
