local Package = require 'packagemanager/package'


local PackageIndex = {}

function PackageIndex.addPackage( index, package )
    assert(package.name,    'Package has no name.')
    assert(package.version, 'Package has no version.')

    local versions = index[package.name]
    if not versions then
        versions = {}
        index[package.name] = versions
    end

    local versionString = tostring(package.version)
    local destPackage = versions[versionString]
    if destPackage then
        Package.mergePackages(destPackage, package)
    else
        versions[versionString] = package
    end
end

function PackageIndex.mergeIndices( destination, source )
    for _, versions in pairs(source) do
        for _, package in pairs(versions) do
            PackageIndex.addPackage(destination, package)
        end
    end
end

function PackageIndex.removePackage( index, package )
    local versionStr = tostring(package.version)
    local versions = index[package.name]
    assert(versions, 'Package does not exist in index.')
    assert(versions[versionStr], 'Package version does not exist in index.')
    assert(versions[versionStr] == package, 'Package differs from index.')
    versions[versionStr] = nil
end


return PackageIndex
