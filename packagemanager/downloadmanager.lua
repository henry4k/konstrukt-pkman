local WorkerManager = require 'packagemanager/WorkerManager'


local function DownloadProcessor()
    local Network = require 'packagemanager/network'

    local EventHandlerMT =
    {
        __index =
        {
            onDownloadBegin = function( self, url, fileName, totalBytes )
                SetTaskProperty('url', url)
                SetTaskProperty('fileName', fileName)
                SetTaskProperty('totalBytes', totalBytes)
                EmitTaskEvent('downloadStarted')
            end,

            onDownloadProgress = function( self, bytesWritten )
                SetTaskProperty('bytesWritten', bytesWritten)
            end,

            onDownloadEnd = function( self )
            end
        }
    }

    return function( url, fileName, unpackZip )
        if fileName then
            local eventHandler = setmetatable({}, EventHandlerMT)
            if unpackZip then
                Network.downloadAndUnpackZipFile(url, fileName, eventHandler)
            else
                Network.downloadFile(url, fileName, eventHandler)
            end
        else
            SetTaskProperty('headers', Network.getResourceHeaders(url))
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

function DownloadManager.createDownload( url, fileName, unpackZip )
    return manager:createTask({url, fileName, unpackZip})
end

function DownloadManager.getActiveDownloads()
    return manager.tasks
end


return DownloadManager
