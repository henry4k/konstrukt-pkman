local semver = require 'semver'
local Misc = require 'packagemanager.misc'


local Version = {}

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
    versionStr = Misc.trim(versionStr)
    local major, minor, patch = versionStr:match('^(%d+)%.?(%d*)%.?(%d*)$')
    return semver(tonumber(major) or default,
                  tonumber(minor) or default,
                  tonumber(patch) or default)
end

local function TryParseAny( expr )
    if expr == '*' then
        return { min = MinimumVersion,
                 max = MaximumVersion }
    end
end

local function TryParseSingle( expr )
    local version = expr:match('^([0-9.]+)$')
    if version then
        return { min = ParseVersion(version, 0),
                 max = ParseVersion(version, math.huge) }
    end
end

---
-- From [NPM](https://docs.npmjs.com/misc/semver#tilde-ranges-123-12-1): 
-- Allows patch-level changes if a minor version is specified on the comparator.
-- Allows minor-level changes if not.
local function TryParseTilde( expr )
    local version = expr:match('^~([0-9.]+)$')
    if version then
        local range = { min = ParseVersion(version, 0),
                        max = ParseVersion(version, math.huge) }
        range.max.patch = math.huge
        return range
    end
end

---
-- From [NPM](https://docs.npmjs.com/misc/semver#caret-ranges-123-025-004): 
-- Allows changes that do not modify the left-most non-zero digit in the
-- [major, minor, patch] tuple. In other words, this allows patch and minor
-- updates for versions 1.0.0 and above, patch updates for versions 0.X
-- >=0.1.0, and *no* updates for versions 0.0.X.
local function TryParseCaret( expr )
    local version = expr:match('^%^([0-9.]+)$')
    if version then
        local min = ParseVersion(version, 0)
        local max
        if min.major > 0 then
            max = semver(min.major, math.huge, math.huge)
        elseif min.minor > 0 then
            max = semver(min.major, min.minor, math.huge)
        else
            max = min
        end
        return { min = min, max = max }
    end
end

local function TryParseRange( expr )
    local minVersion, maxVersion = expr:match('^([0-9.]+)%s*-%s*([0-9.]+)$')
    if minVersion then
        return { min = ParseVersion(minVersion, 0),
                 max = ParseVersion(maxVersion, math.huge) }
    end
end

local function TryParseComparator( expr )
    local comparator, version = expr:match('^([<>]=?)%s*([0-9.]+)$')
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

local RangeMT = {}
function RangeMT:__tostring()
    return self.expression
end
function RangeMT:__eq( other )
    return self.min == other.min and
           self.max == other.max
end

function Version.parseVersionRange( rangeExpr )
    -- *       =>  0.0.0 - INF.INF.INF
    -- a.b.c - x.y.z
    -- a.b.c   =>  a.b.c - a.b.c
    -- a.b     =>  a.b.0 - a.b.INF
    -- a       =>  a.0.0 - a.INF.INF
    -- >a.b.c  =>  a.b.c+1 - INF.INF.INF
    -- >=a.b.c =>  a.b.c - INF.INF.INF
    -- <a.b.c  =>  0.0.0 - a.b.c-1
    -- <=a.b.c =>  0.0.0 - a.b.c
    -- ~a.b.c  =>  a.b.c - a.b.INF
    -- ^a.b.c  =>  a.b.c - a.INF.INF
    rangeExpr = Misc.trim(rangeExpr)
    local range = TryParseAny(rangeExpr) or
                  TryParseSingle(rangeExpr) or
                  TryParseTilde(rangeExpr) or
                  TryParseCaret(rangeExpr) or
                  TryParseRange(rangeExpr) or
                  TryParseComparator(rangeExpr)
    assert(range, 'Malformatted range expression.')
    range.expression = rangeExpr
    return setmetatable(range, RangeMT)
end

function Version.versionToVersionRange( version )
    return setmetatable({ min = version,
                          max = version,
                          expression = tostring(version) }, RangeMT)
end

function Version.isVersionInVersionRange( version, range )
    return version >= range.min and
           version <= range.max
end

function Version.getMatchingPackages( packages, range )
    local results = {}
    for _, package in pairs(packages) do
        if Version.isVersionInVersionRange(package.version, range) then
            table.insert(results, package)
        end
    end
    return results
end


return Version
