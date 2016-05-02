local Package = require 'packagemanager/package'


local PackageIndex = {}

function PackageIndex.create()
    return {}
end

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

local function PropertyMatchesComparator( property, comparator )
    if type(comparator) == 'function' then
        return comparator(property)
    else
        return property == comparator
    end
end

local function PackageMatchesComparators( package, comparators )
    for propertyName, comparator in pairs(comparators) do
        local property = package[propertyName]
        if not PropertyMatchesComparator(property, comparator) then
            return false
        end
    end
    return true
end

local function IndexQueryCoro( index, comparators )
    comparators = comparators or {}

    if type(comparators.name) == 'string' then
        -- Optimized search:
        local versions = index[comparators.name]
        if versions then
            for _, package in pairs(versions) do
                if PackageMatchesComparators(package, comparators) then
                    coroutine.yield(package)
                end
            end
        end
    else
        -- Generic search:
        for packageName, versions in pairs(index) do
            for _, package in pairs(versions) do
                if PackageMatchesComparators(package, comparators) then
                    coroutine.yield(package)
                end
            end
        end
    end
end

function PackageIndex.packages( index, comparators )
    return coroutine.wrap(function() IndexQueryCoro(index, comparators) end)
end

function PackageIndex.gatherPackages( index, comparators )
    local result = {}
    for package in PackageIndex.packages(index, comparators) do
        table.insert(result, package)
    end
    return result
end


return PackageIndex
