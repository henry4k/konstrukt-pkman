local misc = {}

local function DisjoinByDelimiterCoro( str, delimiterPattern )
    assert(not delimiterPattern:match('[()]'), 'Delimiter pattern may not have groups.')
    local pattern = '()'..delimiterPattern..'()'
    local startPos = 1
    while true do
        local matchStart, matchEnd = str:match(pattern, startPos)
        if matchStart then
            coroutine.yield(str:sub(startPos, matchStart-1))
            startPos = matchEnd
        else
            coroutine.yield(str:sub(startPos))
            break
        end
    end
end

function misc.disjoinByDelimiter( str, delimiterPattern )
    return coroutine.wrap(function() DisjoinByDelimiterCoro(str, delimiterPattern) end)
end

function misc.tablesAreEqual( a, b )
    local seenKeys = {}
    for k, vA in pairs(a) do
        local vB = b[k]

        local tA = type(vA)
        local tB = type(vB)
        if tA ~= tB then
            return false
        end

        if tA == 'table' then
            if not misc.compareTablesRecursively(vA, vB) then
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


return misc
