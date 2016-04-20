local lfs = require 'lfs'
local fsutils = require 'fsutils'
local Package = require 'package'


local PackageDB = {}

function PackageDB.addPackage( db, package )
    assert(package.name,    'Package has no name.')
    assert(package.version, 'Package has no version.')

    local versions = db[package.name]
    if not versions then
        versions = {}
        db[package.name] = versions
    end

    local versionString = tostring(package.version)
    local destPackage = versions[versionString]
    if destPackage then
        Package.mergePackages(destPackage, package)
    else
        versions[versionString] = package
    end
end

function PackageDB.mergeDatabases( destination, source )
    for packageName, versions in pairs(source) do
        for _, package in pairs(versions) do
            PackageDB.addPackage(destination, package)
        end
    end
end

local function BuildPackageBaseName( name, version )
    return string.format('%s.%s', name, version)
end

local function IsLocalPackage( fileName, fileInfo )
    local mode = lfs.attributes(fileName, 'mode')
    if mode == 'directory' then
        local metaFileName = fsutils.path(fileName, 'meta.json')
        return lfs.attributes(metaFileName, 'mode') == 'file'
    elseif mode == 'file' then
        return fileName:match('%.zip$')
    end
end

function PackageDB.gatherInstalledPackages( db, searchPaths )
    local packages = {}
    for _, searchPath in ipairs(searchPaths) do
        for entry in lfs.dir(searchPath) do
            local fileName = fsutils.path(searchPath, entry)
            local fileInfo = fsutils.parsePackageFileName(fileName)
            if fileInfo and IsLocalPackage(fileName, fileInfo) then
                local baseName = BuildPackageBaseName(fileInfo.package,
                                                      fileInfo.version)
                if not packages[baseName] then
                    packages[baseName] = Package.readLocalPackage(fileName)
                end
            end
        end
    end

    for _, package in pairs(packages) do
        PackageDB.addPackage(db, package)
    end
end

function PackageDB.gatherSelectedPackageVersions()
    local packageVersions = {}
    for entry in lfs.dir('selection') do
        local fileInfo = fsutils.parsePackageFileName(entry)
        if fileInfo then
            local baseName = BuildPackageBaseName(fileInfo.package,
                                                  fileInfo.version)
            table.insert(packageVersions, {name    = fileInfo.package,
                                           version = fileInfo.version})
        end
    end
    return packageVersions
end


-- PackageDB.getUnusedPackages( installedPackages, selectedPackages )


return PackageDB
