local Package = require 'packagemanager/package'


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
    for _, versions in pairs(source) do
        for _, package in pairs(versions) do
            PackageDB.addPackage(destination, package)
        end
    end
end

function PackageDB.removePackage( db, package )
    local versionStr = tostring(package.version)
    local versions = db[package.name]
    assert(versions, 'Package does not exist in DB.')
    assert(versions[versionStr], 'Package version does not exist in DB.')
    assert(versions[versionStr] == package, 'Package differs from DB.')
    versions[versionStr] = nil
end


return PackageDB
