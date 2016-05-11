local Package = require 'packagemanager/package'
local Misc = require 'packagemanager/misc'


local PackageIndex = {}

function PackageIndex.create()
    return {}
end

local function AddPackageAlternative( index,
                                      providedName,
                                      providedVersion,
                                      package )
    local alternatives = Misc.createTableHierachy(index,
                                                  providedName,
                                                  tostring(providedVersion))
    local destPackage = alternatives[package.name]
    if destPackage then
        Package.mergePackages(destPackage, package)
    else
        alternatives[package.name] = package
    end
end

local function RemovePackageAlternative( index,
                                         providedName,
                                         providedVersion,
                                         package )
    local alternatives = Misc.traverseTableHierachy(index,
                                                    providedName,
                                                    tostring(providedVersion))
    assert(alternatives, 'Package does not exist in index.')
    assert(alternatives[package.name], 'Package alternative does not exist in index.')
    assert(alternatives[package.name] == package, 'Package differs from index.')
    alternatives[package.name] = nil
end

function PackageIndex.addPackage( index, package )
    assert(package.name,    'Package has no name.')
    assert(package.version, 'Package has no version.')

    AddPackageAlternative(index, package.name, package.version, package)
    if package.provides then
        for providedName, providedVersion in pairs(package.provides) do
            AddPackageAlternative(index, providedName, providedVersion, package)
        end
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
    RemovePackageAlternative(index, package.name, package.version, package)
    if package.provides then
        for providedName, providedVersion in pairs(package.provides) do
            RemovePackageAlternative(index, providedName, providedVersion, package)
        end
    end
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
            for _, alternatives in pairs(versions) do
                for _, package in pairs(alternatives) do
                    if PackageMatchesComparators(package, comparators) then
                        coroutine.yield(package)
                    end
                end
            end
        end
    else
        -- Generic search:
        for packageName, versions in pairs(index) do
            for _, alternatives in pairs(versions) do
                for _, package in pairs(alternatives) do
                    if PackageMatchesComparators(package, comparators) then
                        coroutine.yield(package)
                    end
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
