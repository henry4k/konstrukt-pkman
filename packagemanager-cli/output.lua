local RichText = require 'packagemanager-cli/RichText'


local Stream = io.stdout

local Features = {}
Features.unicode = false
Features.ansiEscapeCodes = false
Features.carriageReturn = false
Features.maxLineLength = 80

-- Magic to detect terminal features:
if os.getenv('TERM') then
    local tputProcess = io.popen('tput colors', 'r')
    if tputProcess then
        local colors = tonumber(tputProcess:read('*a'))
        tputProcess:close()
        tputProcess = io.popen('tput cols', 'r')
        local columns = tonumber(tputProcess:read('*a'))
        tputProcess:close()

        Features.ansiEscapeCodes = colors >= 8
        Features.maxLineLength = columns
        Features.carriageReturn = true
    end

    -- This just tests whether the system uses utf-8, but it should do the trick.
    local lang = os.getenv('LANG')
    if lang and lang:match('UTF%-8') then
        Features.unicode = true
    end
end

local Output = {}
Output.stream = Stream
Output.features = Features

if Features.ansiEscapeCodes then
    local attributes = {}
    attributes.reset = 0
    attributes.bold = 1
    attributes.underline = 4
    attributes.negative = 7
    attributes.overline = 53 -- not always supported

    local colorNames = {'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white'}
    for i, name in ipairs(colorNames) do
        local o = i-1
        attributes[name] = 30+o
        attributes[name..'Bg'] = 40+o
    end

    function Output.attributes( ... )
        local values = {...}
        for i, name in ipairs(values) do
            values[i] = assert(attributes[name], 'No such attribute.')
        end
        local str =
            table.concat{string.char(27), '[', table.concat(values, ';'), 'm'}
        return RichText(str, 0)
    end
else
    function Output.attributes( ... )
        return ''
    end
end

if Features.carriageReturn then
    local LineLength = 0

    function Output.rewriteLine( str )
        Stream:write('\r', tostring(str))
        local len = #str
        if len < LineLength then
            Stream:write(string.rep(' ', LineLength-len))
        end
        LineLength = len
    end

    function Output.log( str )
        if LineLength > 0 then
            Output.rewriteLine(str)
            Stream:write('\n')
            LineLength = 0
        else
            Stream:write(tostring(str), '\n')
        end
    end

    function Output.logError( str )
        Output.log(Output.attributes('red')..
                   str..
                   Output.attributes('reset'))
    end
else
    function Output.log( str )
        Stream:write(tostring(str), '\n')
    end

    function Output.logError( str )
        io.stderr:write(tostring(str), '\n')
    end
end

return Output
