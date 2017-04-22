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

function Misc.readProcess( program )
    local f = assert(io.popen(program, 'r'))
    local output = f:read('*a')
    f:close()
    return output
end

if package.config:sub(1,1) == '\\' then
    Misc.operatingSystem = 'windows'
else
    Misc.operatingSystem = 'unix'
end

local ProcessorArchitecture
function Misc.getProcessorArchitecture()
    if not ProcessorArchitecture then
        if Misc.operatingSystem == 'windows' then
            local out = Misc.readProcess('reg query "HKLM\\System\\CurrentControlSet\\Control\\Session Manager\\Environment" /v PROCESSOR_ARCHITECTURE')
            local winArch = (out or ''):match('PROCESSOR_ARCHITECTURE%s+REG_SZ%s+([^%s]+)')
            local mapping = {AMD64 = 'x86_64',
                             x64   = 'x86_64',
                             x86   = 'i686'}
            ProcessorArchitecture = assert(mapping[winArch], 'Unknown processor architecture.')
        else
            ProcessorArchitecture = Misc.readProcess('uname -m')
        end
    end
    return ProcessorArchitecture
end

function Misc.joinLists( ... )
    local lists = {...}
    local result = assert(lists[1], 'Needs at least one list.')
    for i = 2, #lists do
        local list = lists[i]
        for _, value in ipairs(list) do
            table.insert(result, value)
        end
    end
    return result
end

local unpack = table.unpack or unpack

function Misc.bind( fn, ... )
    local staticArgCount = select('#', ...)
    if staticArgCount == 1 then -- optimized implementation
        local staticArg = ...
        return function( ... )
            return fn(staticArg, ...)
        end
    else -- generic implementation
        local staticArgs = {...}
        assert(#staticArgs == staticArgCount, 'Can\'t store var staticArgs in list - maybe passed a nil argument?')
        return function( ... )
            local args = Misc.joinLists(staticArgs, {...})
            return fn(unpack(args))
        end
    end
end

function Misc.writeFile( destFile, sourceFile )
    while true do
        local chunk = sourceFile:read(1024)
        if chunk and #chunk > 0 then
            destFile:write(chunk)
        else
            break
        end
    end
end

local Kibibyte = math.pow(2, 10)
local Mebibyte = math.pow(2, 20)
function Misc.getByteUnit( reference )
    if reference >= Mebibyte then
        return 'MiB', Mebibyte
    elseif reference >= Kibibyte then
        return 'KiB', Kibibyte
    else
        return 'bytes', 1
    end
end


return Misc
