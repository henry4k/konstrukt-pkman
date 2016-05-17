local Misc = {}

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

function Misc.disjoinByDelimiter( str, delimiterPattern )
    return coroutine.wrap(function() DisjoinByDelimiterCoro(str, delimiterPattern) end)
end

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
            if not Misc.tablesAreEqual(vA, vB) then
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

function Misc.createTableHierachy( t, ... )
    for _, key in ipairs({...}) do
        if not t[key] then
            t[key] = {}
        end
        t = t[key]
    end
    return t
end

function Misc.traverseTableHierachy( t, ... )
    for _, key in ipairs({...}) do
        if not t[key] then
            return nil
        end
        t = t[key]
    end
    return t
end

if package.config:sub(1,1) == '\\' then
    Misc.os = 'windows'
else
    Misc.os = 'unix'
end

function Misc.getCurrentDirectory()
    local dir
    if Misc.os == 'windows' then
        dir = os.getenv('CD')
    else
        dir = os.getenv('PWD')
    end
    return assert(dir)
end


return Misc
