local Misc = require 'Misc'


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
end

function Package.buildBaseName( name, version )
    return string.format('%s.%s', name, version)
end


return Package
