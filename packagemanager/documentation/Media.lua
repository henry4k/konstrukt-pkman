local cmark = require 'cmark'
local Path  = require('packagemanager/path').unix
local Misc  = require 'packagemanager/misc'
local Unit  = require 'packagemanager/unit'
local Utils = require 'packagemanager/documentation/utils'


local Processor = {}
Processor.__index = Processor
Processor.nodeFilter = {cmark.NODE_IMAGE}

local MediaTypes =
{
    png =
    {
        maxSize = math.pow(2, 20) -- 1 MiB
    },
    webm =
    {
        maxSize = math.pow(2, 20)*3, -- 3 MiB
        nodeTransformator = function()
            error('WebM is not supported yet.')
        end
    }
}

local function GetMediaType( extension )
    return MediaTypes[extension]
end

function Processor:leaveNode( node )
    local url = cmark.node_get_url(node)

    if not Utils.isUrlLocalPath(url) then
        error('External media is not allowed.')
    end

    if url:match('^/') then
        error('Can\'t handle absolute paths yet.')
    end

    local extension = Path.extension(url)
    local mediaType = GetMediaType(extension)
    if not mediaType then
        error('File type is not supported in a media element.')
    end

    if mediaType.nodeTransformator then
        mediaType.nodeTransformator(node)
    end

    local fileName = Path.resolveRelative(url, self.sourceDir)
    if fileName:match('^%.%./') then
        error('Relative paths may not leave the package directory.')
    end

    self.mediaFiles[fileName] = true
end

local function CreateProcessor( sourceDir )
    local self = { sourceDir = sourceDir,
                   mediaFiles = {} }
    return setmetatable(self, Processor)
end

local function AddMediaFiles( destination, source )
    for fileName in pairs(source) do
        destination[fileName] = true
    end
end

local function ProcessMediaFiles( mediaFiles, sourceTree, resultTree )
    for fileName in pairs(mediaFiles) do
        -- Check file size:
        local size = sourceTree:getFileAttributes(fileName).size
        local extension = Path.extension(fileName)
        local mediaType = GetMediaType(extension)
        if size > mediaType.maxSize then
            local unit = Unit.get('bytes', mediaType.maxSize)
            print(string.format('%s is too large: %s (Maximum is %s)',
                fileName, unit:format(size), unit:format(mediaType.maxSize)))
        end

        -- Copy file:
        local sourceFile = assert(sourceTree:openFile(fileName, 'r'))
        local resultFile = assert(resultTree:openFile(fileName, 'w'))
        Misc.writeFile(resultFile, sourceFile)
        sourceFile:close()
        resultFile:close()
    end
end

return { createProcessor = CreateProcessor,
         addMediaFiles = AddMediaFiles,
         processMediaFiles = ProcessMediaFiles }
