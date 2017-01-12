local Misc = require 'packagemanager/misc'


local Package = {}

function Package.mergePackages( destination, source )
    for key, sourceValue in pairs(source) do
        local destValue = destination[key]
        if destValue then
            local sourceValueType = type(sourceValue)
            local destValueType   = type(destValue)
            if destValueType ~= sourceValueType then
                error(string.format('Type mismatch while merging %s:  %s <> %s',
                                    key, destValueType, sourceValueType))
            end
            if destValueType == 'table' then
                if not Misc.tablesAreEqual(destValue, sourceValue) then
                    error(string.format('Tables of property %s are not equal.', key))
                end
            end
        else
            destination[key] = sourceValue
        end
    end

    local destMt = getmetatable(destination)
    local sourceMt = getmetatable(source)
    if destMt and sourceMt then
        assert(destMt ~= sourceMt, 'Cannot merge metatables.')
    elseif sourceMt then
        setmetatable(destination, sourceMt)
    end
end

function Package.buildBaseName( name, version )
    return string.format('%s.%s', name, tostring(version))
end

function Package.genId( package )
    return string.format('%s/%s/%s', package.name, package.version, package.providerId or '')
end

---
-- @return It returns `name`, `version` and `providerId`. The provider id may be an emtpy string.
-- Returns `nil` if parsing failed.
function Package.parseId( id )
    return id:match('^(.-)/(.-)/(.*)$')
end


return Package
