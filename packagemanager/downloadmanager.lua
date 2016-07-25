local JobManager = require 'packagemanager/jobmanager'


local function DownloadProcessor()
    local Network = require 'packagemanager/network'

    local EventHandlerMT =
    {
        __index =
        {
            onDownloadBegin = function( self, fileName, url, totalBytes )
                SetJobProperty('fileName', fileName)
                SetJobProperty('url', url)
                SetJobProperty('totalBytes', totalBytes)
            end,

            onDownloadProgress = function( self, bytesWritten )
                SetJobProperty('bytesWritten', bytesWritten)
            end,

            onDownloadEnd = function( self )
            end
        }
    }

    return function( fileName, url, unpackZip )
        local eventHandler = setmetatable({}, EventHandlerMT)
        if unpackZip then
            Network.downloadAndUnpackZipFile(fileName, url, eventHandler)
        else
            Network.downloadFile(fileName, url, eventHandler)
        end
    end
end

local manager = JobManager.create{ typeName = 'download',
                                   processor = DownloadProcessor }

local DownloadManager = {}

function DownloadManager.finalize()
    manager:destroy()
    manager = nil
end

function DownloadManager.update()
    manager:update()
end

function DownloadManager.startDownload( fileName, url, unpackZip, eventHandler )
    return manager:createJob({fileName, url, unpackZip}, eventHandler)
end

function DownloadManager.getActiveDownloads()
    return manager.jobs
end


return DownloadManager
