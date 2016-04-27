local Misc = {}

function Misc.tablesAreEqual( a, b )
    local seenKeys = {}
    for k, vA in pairs(a) do
        local vB = b[k]

        local tA = type(vA)
        local tB = type(vB)
        if tA ~= tB then
            return false
        end

        if tA == 'table' then
            if not Misc.compareTablesRecursively(vA, vB) then
                return false
            end
        else
            if vA ~= vB then
                return false
            end
        end

        seenKeys[k] = true
    end

    for k, _ in pairs(b) do
        if not seenKeys[k] then
            return false
        end
    end

    return true
end

function Misc.copyTable( t )
    local r = {}
    for k, v in pairs(t) do
        r[k] = v
    end
    return r
end

function Misc.trim( s )
    return s:match('^%s*(.*)%s*$')
end


return Misc
