#!/usr/bin/env lua
-- vim: set filetype=lua:
require 'Test.More'
local Version = require 'version'

plan(6*6)

local function testVersionRange( rangeExpr, min, max )
    local range = Version.parseVersionRange(rangeExpr)
    is(range.min.major, min[1], rangeExpr..' min.major')
    is(range.min.minor, min[2], rangeExpr..' min.minor')
    is(range.min.patch, min[3], rangeExpr..' min.patch')
    is(range.max.major, max[1], rangeExpr..' max.major')
    is(range.max.maxor, max[2], rangeExpr..' max.maxor')
    is(range.max.patch, max[3], rangeExpr..' max.patch')
end
local inf = math.huge

testVersionRange('42', {42,0,0}, {42,inf,inf})
testVersionRange('42-43', {42,0,0}, {43,inf,inf})
testVersionRange('>42', {42,0,1}, {inf,inf,inf})
testVersionRange('>=42', {42,0,0}, {inf,inf,inf})
testVersionRange('<42', {0,0,0}, {41,inf,inf})
testVersionRange('<=42', {1,0,0}, {42,0,0})
