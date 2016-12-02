local Package = require 'packagemanager/package'
local Misc = require 'packagemanager/misc'
local Version = require 'packagemanager/version'


local PackageDB = {}

function PackageDB.create()
    return {}
end

local function RemovePackageAlternative( db,
                                         providedName,
                                         providedVersion,
                                         package )
    local alternatives = Misc.traverseTableHierachy(db,
                                                    providedName,
                                                    tostring(providedVersion))
    assert(alternatives, 'Package does not exist in db.')
    assert(alternatives[package.name], 'Package alternative does not exist in db.')
    assert(alternatives[package.name] == package, 'Package differs from db.')
    alternatives[package.name] = nil
end

local function CreateVirtualPackage( name, version, providingPackage )
    local versionRange = Version.versionToVersionRange(providingPackage.version)
    return { name = name,
             version = version,
             virtual = true,
             dependencies = { [providingPackage.name] = versionRange },
             provider = providingPackage }
end

function PackageDB.addPackage( db, package )
    assert(package.name,    'Package has no name.')
    assert(package.version, 'Package has no version.')

    local alternatives = Misc.createTableHierachy(db,
                                                  package.name,
                                                  tostring(package.version))
    local id = Package.genId(package)
    local destPackage = alternatives[id]
    if destPackage then
        Package.mergePackages(destPackage, package)
    else
        alternatives[id] = package
    end

    if package.provides then
        for providedName, providedVersion in pairs(package.provides) do
            local virtualPackage = CreateVirtualPackage(providedName,
                                                        providedVersion,
                                                        package)
            PackageDB.addPackage(db, virtualPackage)
        end
    end
end

function PackageDB.mergeIndices( destination, source )
    for _, versions in pairs(source) do
        for _, package in pairs(versions) do
            PackageDB.addPackage(destination, package)
        end
    end
end

function PackageDB.removePackage( db, package )
    local alternatives = Misc.traverseTableHierachy(db,
                                                    package.name,
                                                    tostring(package.version))
    assert(alternatives, 'Package does not exist in db.')
    local id = Package.genId(package)
    assert(alternatives[id], 'Package alternative does not exist in db.')
    assert(alternatives[id] == package, 'Package differs from db.')
    alternatives[id] = nil

    if package.provides then
        for providedPackage in PackageDB.packages(db, {provider = package}) do
            PackageDB.removePackage(db, providedPackage)
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

local function DBQueryCoro( db, comparators )
    comparators = comparators or {}

    if type(comparators.name) == 'string' then
        -- Optimized search:
        local versions = db[comparators.name]
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
        for packageName, versions in pairs(db) do
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

function PackageDB.packages( db, comparators )
    return coroutine.wrap(function() DBQueryCoro(db, comparators) end)
end

function PackageDB.gatherPackages( db, comparators )
    local result = {}
    for package in PackageDB.packages(db, comparators) do
        table.insert(result, package)
    end
    return result
end


return PackageDB
