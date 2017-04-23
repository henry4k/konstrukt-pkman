local Package = require 'packagemanager/package'
local Misc = require 'packagemanager/misc'
local Version = require 'packagemanager/version'


local PackageDB = {}
PackageDB.__index = PackageDB

local function CreateVirtualPackage( name, version, providingPackage )
    local versionRange = Version.versionToVersionRange(providingPackage.version)
    return { name = name,
             version = version,
             type = providingPackage.type,
             virtual = true,
             dependencies = { [providingPackage.name] = versionRange },
             providerId = Package.genId(providingPackage) }
end

function PackageDB:addPackage( package )
    assert(package.name,    'Package has no name.')
    assert(package.version, 'Package has no version.')

    local alternatives = Misc.createTableHierachy(self._packages,
                                                  package.name,
                                                  tostring(package.version))
    local providerId = package.providerId or Package.genId(package)
    --local providerId = package.providerId or ''
    local destPackage = alternatives[providerId]
    if destPackage then
        Package.mergePackages(destPackage, package)
    else
        alternatives[providerId] = package
    end

    if package.provides then
        for providedName, providedVersion in pairs(package.provides) do
            local virtualPackage = CreateVirtualPackage(providedName,
                                                        providedVersion,
                                                        package)
            self:addPackage(virtualPackage)
        end
    end
end

function PackageDB:mergeIndices( source )
    for _, versions in pairs(source._packages) do
        for _, package in pairs(versions) do
            self:addPackage(package)
        end
    end
end

function PackageDB:removePackage( package )
    local alternatives = Misc.traverseTableHierachy(self._packages,
                                                    package.name,
                                                    tostring(package.version))
    assert(alternatives, 'Package does not exist in DB.')
    local id = Package.genId(package)
    assert(alternatives[id], 'Package alternative does not exist in DB.')
    assert(alternatives[id] == package, 'Package differs from DB.')
    alternatives[id] = nil

    if package.provides then
        for providedPackage in self:packages{providerId = id} do
            assert(providedPackage.virtual)
            self:removePackage(providedPackage)
        end
    end
end

function PackageDB:getPackageById( id )
    local name, version, providerId = Package.parseId(id)
    if name then
        local package = Misc.traverseTableHierachy(self._packages, name, version, providerId)
        if package then
            return package
        else
            return nil, 'No package for this ID: '..id
        end
    else
        return nil, 'Can\'t parse ID: '..id
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

local function DBQueryCoro( self, comparators )
    comparators = comparators or {}

    if type(comparators.name) == 'string' then
        -- Optimized search:
        local versions = self._packages[comparators.name]
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
        for packageName, versions in pairs(self._packages) do
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

function PackageDB:packages( comparators )
    return coroutine.wrap(function() DBQueryCoro(self, comparators) end)
end

function PackageDB:gatherPackages( comparators )
    local result = {}
    for package in self:packages(comparators) do
        table.insert(result, package)
    end
    return result
end


return function()
    return setmetatable({ _packages = {} }, PackageDB)
end
