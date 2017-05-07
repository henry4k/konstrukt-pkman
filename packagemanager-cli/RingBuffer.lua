local floor = math.floor


local RingBuffer = {}

local function MapIndexToRing( self, i )
    return ((self._end + i - 1) % #self._buffer) + 1
end

function RingBuffer:__index( i )
    if floor(i) == i and
       i >= 1 and
       i <= #self._buffer then
        return self._buffer[MapIndexToRing(self, i)]
    end
end

function RingBuffer:__len()
    return #self._buffer
end

local function Iterate( self, i )
    i = i + 1
    if i <= #self._buffer then
        return i, self[i]
    end
end

-- Used by Lua 5.2. Lua 5.3 does not need this anymore:
-- see http://www.lua.org/manual/5.3/manual.html#8.2
function RingBuffer:__ipairs()
    return Iterate, self, 0
end

local function Append( self, v )
    local i = (self._end % self._maxSize) + 1
    self._end = i
    self._buffer[i] = v
end

return function( maxSize )
    local self = {append = Append,
                  _buffer = {},
                  _maxSize = maxSize,
                  _end = 0}
    return setmetatable(self, RingBuffer)
end
