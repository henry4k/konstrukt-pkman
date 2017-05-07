local function RoundToNearestInteger( value )
    local floor = math.floor(value)
    if value-floor < 0.5 then
        return floor
    else
        return floor+1
    end
end

local function RenderBar( width, completion, blocks )
    local function Block( completion )
        return blocks[RoundToNearestInteger((#blocks-1) * completion)+1]
    end

    local filled = width*completion
    local filledFloor = math.floor(filled)
    local filledCeil  = math.ceil(filled)
    local halfFilled = filled-filledFloor

    local buffer = {}

    local filledBlock = Block(1)
    table.insert(buffer, string.rep(Block(1), filledFloor))

    if halfFilled > 0 then
        table.insert(buffer, Block(halfFilled))
    end

    local emptyBlock = Block(0)
    table.insert(buffer, string.rep(Block(0), width-filledCeil))

    return table.concat(buffer)
end

local UnicodeBlocks = {' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉', '█'}
local function RenderUnicodeBar( width, completion )
    return RenderBar(width, completion, UnicodeBlocks)
end

local SimpleBlocks = {' ', '='}
local function RenderSimpleBar( width, completion )
    return RenderBar(width, completion, SimpleBlocks)
end

return {renderUnicodeBar = RenderUnicodeBar,
        renderSimpleBar  = RenderSimpleBar}
