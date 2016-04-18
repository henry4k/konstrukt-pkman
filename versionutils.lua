local semver = require 'semver'
local misc = require 'misc'


local versionutils = {}

local function ChangableByOne( n )
    return n > 0 and n < math.huge
end

local function IncrementVersion( v )
    if v.patch < math.huge then
        return semver(v.major, v.minor, v.patch+1)
    elseif v.minor < math.huge then
        return semver(v.major, v.minor+1, 0)
    elseif v.major < math.huge then
        return semver(v.major+1, 0, 0)
    else
        error('Cannot increment INF.INF.INF')
        return v
    end
end

local function DecrementVersion( v )
    if ChangableByOne(v.patch) then
        return semver(v.major, v.minor, v.patch-1)
    elseif ChangableByOne(v.minor) then
        return semver(v.major, v.minor-1, math.huge)
    elseif ChangableByOne(v.major) then
        return semver(v.major-1, math.huge, math.huge)
    else
        error('Cannot decrement 0.0.0')
        return v
    end
end

local MaximumVersion = semver(math.huge, math.huge, math.huge)
local MinimumVersion = semver(0, 0, 0)

local function ParseVersion( versionStr, default )
    local major, minor, patch = versionStr:match('^%s*(%d+)%.?(%d*)%.?(%d*)%s*$')
    return semver(tonumber(major) or default,
                  tonumber(minor) or default,
                  tonumber(patch) or default)
end

local function TryParseSingle( expr )
    local version = expr:match('^%s*([0-9.]+)%s*$')
    if version then
        return { min = ParseVersion(version, 0),
                 max = ParseVersion(version, math.huge) }
    end
end

local function TryParseRange( expr )
    local minVersion, maxVersion = expr:match('^%s*([0-9.]+)%s*-%s*([0-9.]+)%s*$')
    if minVersion then
        return { min = ParseVersion(minVersion, 0),
                 max = ParseVersion(maxVersion, math.huge) }
    end
end

local function TryParseComparator( expr )
    local comparator, version = expr:match('^%s*([<>]=?)%s*([0-9.]+)%s*$')
    if comparator then
        if comparator == '>' then
            return { min = IncrementVersion(ParseVersion(version, 0)),
                     max = MaximumVersion }
        elseif comparator == '>=' then
            return { min = ParseVersion(version, 0),
                     max = MaximumVersion }
        elseif comparator == '<' then
            return { min = MinimumVersion,
                     max = DecrementVersion(ParseVersion(version, math.huge)) }
        elseif comparator == '<=' then
            return { min = MinimumVersion,
                     max = ParseVersion(version, math.huge) }
        end
    end
end

function versionutils.parseVersionRange( rangeExpr )
    -- a.b.c - x.y.z
    -- a.b.c   =>  a.b.c - a.b.c
    -- a.b     =>  a.b.0 - a.b.INF
    -- a       =>  a.0.0 - a.INF.INF
    -- >a.b.c  =>  a.b.c+1 - INF.INF.INF
    -- >=a.b.c =>  a.b.c - INF.INF.INF
    -- <a.b.c  =>  0.0.0 - a.b.c-1
    -- <=a.b.c =>  0.0.0 - a.b.c
    local range = TryParseSingle(rangeExpr) or
                  TryParseRange(rangeExpr) or
                  TryParseComparator(rangeExpr)
    assert(range, 'Malformatted range expression.')
    return range
end

function versionutils.isVersionInVersionRange( version, range )
    return version >= range.min and
           version <= range.max
end

function versionutils.getMatchingPackages( packages, range )
    local results = {}
    for _, package in pairs(packages) do
        if versionutils.isVersionInVersionRange(package.version, range) then
            table.insert(results, package)
        end
    end
    return results
end

local function Max( a, b )
    if a > b then
        return a
    else
        return b
    end
end

local function Min( a, b )
    if a < b then
        return a
    else
        return b
    end
end

--- Compute common subset of both ranges.
function versionutils.mergeVersionRanges( a, b )
    local min = Max(a.min, b.min)
    local max = Min(a.max, b.max)
    if min < max then
        return { min = min, max = max }
    else
        return nil, 'Empty range.'
    end
end


return versionutils
