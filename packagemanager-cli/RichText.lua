local RichText = {}

local EmptyRichText = setmetatable({str = '', charCount = 0}, RichText)

local function IsRichText( value )
    return getmetatable(value) == RichText
end

local function Utf8Len( str )
    local len = #str
    for s, e in str:gmatch('()[\xC2-\xF4][\x80-\xBF]*()') do
        len = len - ((e-s)-1)
    end
    return len
end

local function CreateRichText( str, charCount )
    if IsRichText(str) then
        assert(not charCount)
        return str
    end

    str = tostring(str)
    charCount = charCount or Utf8Len(str)
    assert(charCount >= 0)
    assert(charCount <= #str)
    return setmetatable({str = str, charCount = charCount}, RichText)
end

function RichText:__newindex()
    error('Modification not allowed.')
end

function RichText:__concat( other )
    other = CreateRichText(other)
    return CreateRichText(self.str .. other.str,
                          self.charCount + other.charCount)
end

function RichText:__len()
    return self.charCount
end

function RichText:__tostring()
    return self.str
end

local function Merge( ... )
    local strings = {}
    local charCount = 0
    for _, value in ipairs{...} do
        value = CreateRichText(value)
        strings[#strings+1] = value.str
        charCount = charCount + value.charCount
    end
    return CreateRichText(table.concat(strings), charCount)
end

return setmetatable({ isRichText = IsRichText,
                      merge = Merge,
                      empty = EmptyRichText },
                    { __call = function( self, ... )
                                   return CreateRichText(...)
                               end })
