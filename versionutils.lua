local semver = require 'semver'
local misc = require 'misc'


local versionutils = {}

-- See: https://github.com/npm/node-semver
-- version range: <comparator set> || <comparator set> ...
-- comparator set: <comparator> <comparator> ...
-- comparator: <operator><version>

local Operators =
{
    ['=']  = function(a,b) return a == b end,
    ['<']  = function(a,b) return a <  b end,
    ['>']  = function(a,b) return a >  b end,
    ['<='] = function(a,b) return a <= b end,
    ['>='] = function(a,b) return a >= b end
}

function versionutils.parseVersionRange( versionRangeStr )
    local versionRange = {}
    for comparatorSetStr in misc.disjoinByDelimiter(versionRangeStr, '%s*||%s*') do
        local comparatorSet = {}
        for comparatorStr in comparatorSetStr:gmatch('[^%s]+') do
            local operatorStr, versionStr = comparatorStr:match('([<>=]*)(.*)')
            assert(operatorStr and versionStr and #versionStr > 0,
                   'Comparator mismatch.')

            if #operatorStr == 0 then
                operatorStr = '='
            end
            local operator = Operators[operatorStr]
            assert(operator, 'Unknown operator.')

            local comparator =
            {
                operator=operator,
                version=semver(versionStr)
            }
            table.insert(comparatorSet, comparator)
        end
        table.insert(versionRange, comparatorSet)
    end
    return versionRange
end

function versionutils.isVersionInVersionRange( version, versionRange )
    for _, comparatorSet in ipairs(versionRange) do
        local matches = true
        for _, comparator in ipairs(comparatorSet) do
            if not comparator.operator(version, comparator.version) then
                matches = false
                break
            end
        end
        if matches then
            return true
        end
    end
    return false
end


return versionutils
