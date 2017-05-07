local function IsInteger( value )
    return math.floor(value) == value
end

local Widgets = {}

---
-- @param size
-- Available line width.  The algorithm tries to fill the whole area, but the
-- rendered string might still be longer or shorter.
--
-- @param widgets
-- A list of widgets that shall be rendered.
--
-- @param properties
-- TODO
--
function Widgets.render( size, widgets, properties )
    local totalBasis = 0
    local totalGrow = 0
    local widgetBasises = {} -- this sounds weird
    for i, widget in ipairs(widgets) do
        local widgetBasis = widget:calcBasis(properties)
        widgetBasises[i] = widgetBasis
        totalBasis = totalBasis + widgetBasis
        totalGrow  = totalGrow  + widget.grow
    end

    if totalGrow == 0 then
        totalGrow = 1 -- prevent division by zero
    end

    local free = 0
    if totalBasis < size then
        free = size - totalBasis
    end

    local nonOverlappingFree = 0
    for _, widget in ipairs(widgets) do
        local widgetFree = free*(widget.grow/totalGrow)
        nonOverlappingFree = nonOverlappingFree + math.floor(widgetFree)
    end
    local overlappingFree = free - nonOverlappingFree
    assert(IsInteger(overlappingFree), 'overlappingFree is not an integer!')
    --local alt = free - math.floor(free/totalGrow) * totalGrow
    --assert(overlappingFree == alt, 'alternative compution is wrong!')

    local round
    local even = (overlappingFree % 2) == 0
    if even then
        round = math.ceil
    else
        round = math.floor
    end

    local buffer = {}
    for i, widget in ipairs(widgets) do
        local widgetSize = widgetBasises[i] + free*(widget.grow/totalGrow)
        if not IsInteger(widgetSize) then
            widgetSize = round(widgetSize)

            -- Alternate ceil and floor:
            if round == math.ceil then
                round = math.floor
            else
                round = math.ceil
            end
        end
        table.insert(buffer, widget:render(widgetSize, properties))
    end
    return table.concat(buffer)
end


local Widget = {}
Widget.__index = Widget

function Widget:calcBasis()
    return self.basis
end

local function CreateWidget( t )
    return setmetatable(t or {}, Widget)
end


local function RenderStatic( widget )
    return widget.text
end
function Widgets.Static( text )
    return CreateWidget{basis = #text,
                        grow = 0,
                        text = text,
                        render = RenderStatic}
end
function Widgets.AnsiEscape( ... )
    local code = table.concat{string.char(27), '[', table.concat({...}, ';'), 'm'}
    return {basis = 0,
            grow = 0,
            text = code,
            render = RenderStatic}
end


local function RenderProperty( widget, _, properties )
    return tostring(properties[widget.propertyName])
end
local function CalcPropertyLength( widget, properties )
    return #RenderProperty(widget, 0, properties)
end
function Widgets.Property( propertyName )
    return CreateWidget{calcBasis = CalcPropertyLength,
                        grow = 0,
                        propertyName = propertyName,
                        render = RenderProperty}
end


local function RenderNothing()
    return ''
end
function Widgets.Nothing()
    return CreateWidget{basis = 0,
                        grow = 0,
                        render = RenderNothing}
end


local function RenderFillPattern( widget, size )
    return string.rep(widget.fillChar, size)
end
function Widgets.FillWith( c, v )
    return CreateWidget{basis = 0,
                        grow = v or 1,
                        fillChar = c,
                        render = RenderFillPattern}
end
function Widgets.Fill( v )
    return Widgets.FillWith(' ', v)
end


return Widgets
