local Misc         = require 'packagemanager/misc'
local Config       = require 'packagemanager/config'
local LocalPackage = require 'packagemanager/localpackage'
local Repository   = require 'packagemanager/repository'
local PackageDB    = require 'packagemanager/packagedb'
local Dependency   = require 'packagemanager/dependency'
local Version      = require 'packagemanager/version'


local utils = {}

function utils.buildPackageDB( options )
    local db = PackageDB.create()
    if options.localPackages then
        LocalPackage.gatherInstalledPackages(db, Config.searchPaths)
    end
    if options.remotePackages then
        for repoName, _ in pairs(Config.repositories) do
            Repository.loadIndex(db, repoName)
        end
    end
    return db
end

local Kibibyte = math.pow(2, 10)
local Mebibyte = math.pow(2, 20)
local function GetByteUnit( reference )
    if reference >= Mebibyte then
        return 'MiB', Mebibyte
    elseif reference >= Kibibyte then
        return 'KiB', Kibibyte
    else
        return 'bytes', 1
    end
end

local DownloadEventHandlerMT =
{
    __index =
    {
        write = function( self )
            local bytesWritten = self.bytesWritten
            io.stdout:write(self.lineStart,
                            string.format(self.format,
                                          (bytesWritten/self.totalBytes)*100,
                                          bytesWritten/self.unit))
        end,

        onDownloadBegin = function( self, fileName, url, totalBytes )
            self.lineStart = string.format('Downloading %s from %s: ', fileName, url)
            self.totalBytes = totalBytes

            local unitName, unit = GetByteUnit(totalBytes)
            self.unit = unit

            local totalBytesStr = string.format('%d', totalBytes/unit)
            self.format = '% 3d%% % '..#totalBytesStr..'d/'..totalBytesStr..' '..unitName

            local onePercent = totalBytes / 100
            self.minimumChange = math.min(onePercent, unit)

            self.lastPrintedBytes = 0
            self.bytesWritten = 0

            self:write()
        end,

        onDownloadProgress = function( self, bytesWritten )
            self.bytesWritten = bytesWritten
            local delta = bytesWritten-self.lastPrintedBytes
            if delta >= self.minimumChange then
                io.stdout:write('\r')
                self:write()
                io.stdout:flush()
                self.lastPrintedBytes = bytesWritten
            end
        end,

        onDownloadEnd = function( self )
            io.stdout:write('\r')
            self:write()
            io.stdout:write('\n')
        end
    }
}
local function CreateDownloadEventHandler()
    return setmetatable({}, DownloadEventHandlerMT)
end

function utils.updateRepos()
    for name, url in pairs(Config.repositories) do
        local eventHandler = CreateDownloadEventHandler()
        Repository.updateIndex(name, url, eventHandler)
    end
end

function utils.markUserRequirements( db )
    for i, requirementGroup in ipairs(Config.requirements) do
        local success, result = pcall(Dependency.resolve, db, requirementGroup)
        if success then
            for _, package in pairs(result) do
                package.required = true
            end
        else
            print(string.format('Can\'t resolve user requirement group %d: %s', i, result))
        end
    end
end

function utils.installRequirements( db )
    local outstandingPackages = {}

    for i, requirementGroup in ipairs(Config.requirements) do
        local success, result = pcall(Dependency.resolve, db, requirementGroup)
        if success then
            for _, package in pairs(result) do
                if not package.localFileName then
                    local key = package.name..tostring(package.version)
                    outstandingPackages[key] = package
                end
            end
        else
            print(string.format('Can\'t resolve user requirement group %d: %s', i, result))
        end
    end

    if next(outstandingPackages) then
        print('Packages that need to be downloaded:')
        for _, package in pairs(outstandingPackages) do
            print(string.format('%s %s', package.name, tostring(package.version)))
        end

        for _, package in pairs(outstandingPackages) do
            local eventHandler = CreateDownloadEventHandler()
            local installPath = assert(Config.searchPaths[1])
            Repository.installPackage(package, installPath, eventHandler)
        end
    end
end

function utils.getPackageInstallationStatus( package )
    if package.required and package.localFileName then
        return 'installed'
    elseif package.required then
        return 'required'
    elseif package.localFileName then
        return 'obsolete'
    else
        return ''
    end
end

function utils.removeObsoletePackages( db )
    for package in PackageDB.packages(db) do
        if not package.required and package.localFileName then
            print(string.format('%s %s', package.name, package.version))
            LocalPackage.remove(db, package)
        end
    end
end


return utils
