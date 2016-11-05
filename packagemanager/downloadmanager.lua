local WorkerManager = require 'packagemanager/WorkerManager'


local function DownloadProcessor()
    local Network = require 'packagemanager/network'

    local EventHandlerMT =
    {
        __index =
        {
            onDownloadBegin = function( self, fileName, url, totalBytes )
                SetTaskProperty('fileName', fileName)
                SetTaskProperty('url', url)
                SetTaskProperty('totalBytes', totalBytes)
            end,

            onDownloadProgress = function( self, bytesWritten )
                SetTaskProperty('bytesWritten', bytesWritten)
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

local manager = WorkerManager{ typeName = 'download',
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
    return manager:createTask({fileName, url, unpackZip}, eventHandler)
end

function DownloadManager.getActiveDownloads()
    return manager.tasks
end


return DownloadManager
