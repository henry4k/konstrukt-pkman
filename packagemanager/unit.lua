local Unit = {}
Unit.__index = Unit

function Unit:__newindex()
    error('Units may not be modified.')
end

function Unit:format( value )
    return string.format('%.1f%s', value/self.size, self.symbol)
end

function Unit:formatStatic( value, prefix, postfix )
    local valueStr = string.format('%.1f', value/self.size)
    local safeWidth = self.baseUnit.safeDecimalCount + 2 -- because of the .1
    local paddingLeft = math.max(safeWidth, #valueStr) - #valueStr

    local symbol = self.symbol
    local maxSymbolWidth = self.baseUnit.maxSymbolWidth
    local paddingRight = maxSymbolWidth - #symbol

    return table.concat{string.rep(' ', paddingLeft),
                        prefix or '',
                        valueStr,
                        symbol,
                        postfix or '',
                        string.rep(' ', paddingRight)}
end


local BaseUnits = {}

local function AddBaseUnit( properties, ... )
    local name = assert(properties.name)
    local units = {...}

    local baseUnit = {units = units}

    local maxSymbolWidth = 0
    local maxValue = 1
    for i, unit in ipairs(units) do
        unit.baseUnit = baseUnit
        setmetatable(unit, Unit)

        if #unit.symbol > maxSymbolWidth then
            maxSymbolWidth = #unit.symbol
        end

        if i > 1 then
            local maxUnitValue = (units[i-1].size-1) / unit.size
            if maxUnitValue > maxValue then
                maxValue = maxUnitValue
            end
        end
    end

    local safeDecimalCount = math.floor(math.log(maxValue, 10)+1)

    baseUnit.maxSymbolWidth = maxSymbolWidth
    baseUnit.largestValue = largestValue
    baseUnit.safeDecimalCount = safeDecimalCount
    BaseUnits[name] = baseUnit
end

AddBaseUnit({name = 'seconds'},
            {name = 'hours',
             symbol = 'h',
             size = 60*60},
            {name = 'minutes',
             symbol = 'min',
             size = 60},
            {name = 'seconds',
             symbol = 's',
             size = 1})

AddBaseUnit({name = 'bytes'},
            {name = 'mebibytes',
             symbol = 'MiB',
             size = math.pow(2, 20)},
            {name = 'kibibytes',
             symbol = 'KiB',
             size = math.pow(2, 10)},
            {name = 'bytes',
             symbol = 'B',
             size = 1})

local function GetUnit( baseUnit, value )
    local baseUnit = assert(BaseUnits[baseUnit], 'No such base unit.')
    local units = baseUnit.units

    local lastUnit
    for _, unit in ipairs(units) do
        if value >= unit.size then
            return unit
        else
            lastUnit = unit
        end
    end
    return lastUnit
end


return { get = GetUnit }
