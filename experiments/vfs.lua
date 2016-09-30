local zip = require 'brimworks.zip'


local vfs = {}

vfs.mountPoints = {}

function vfs.mount( zipFileName, mountPoint )
    assert(zipFileName:match('%.zip$'), 'Only ZIP archives can be mounted.')
    vfs.mountPoints[mountPoint] = zipFileName
end

local function VfsLoader( moduleName, t )
    local zipFile = t.zipFile
    local zipFileName = t.zipFileName
    local path = t.path

    local size = assert(zipFile:stat(path)).size
    local file = assert(zipFile:open(path))
    local content = file:read(size)

    file:close()
    zipFile:close()

    local chunk = assert(load(content, zipFileName..'/'..path, 't'))
    return chunk()
end

local function VfsSearcher( moduleName )
    local mountPoint, subPath = moduleName:match('^(.-)%.(.*)$')
    if not mountPoint then
        mountPoint = moduleName
        subPath = nil
    end

    local zipFileName = vfs.mountPoints[mountPoint]
    if zipFileName then
        local zipFile, zipErr = zip.open(zipFileName)
        if not zipFile then
            return zipErr
        end

        if subPath and #subPath then
            for _, dirSep in ipairs({'/', '\\'}) do
                for _, suffix in ipairs({'.lua', dirSep..'init.lua'}) do
                    local path = subPath:gsub('%.', dirSep)..suffix
                    if zipFile:stat(path) then
                        return VfsLoader, {zipFile = zipFile,
                                           zipFileName = zipFileName,
                                           path = path}
                    end
                end
            end
        elseif zipFile:stat('init.lua') then
            return VfsLoader, {zipFile = zipFile,
                               zipFileName = zipFileName,
                               path = 'init.lua'}
        end

        zipFile:close()
    end
end

function vfs.install()
    if package.searchers then
        table.insert(package.searchers, VfsSearcher)
    else
        table.insert(package.loaders, VfsSearcher)
    end
end

return vfs
