#!/usr/bin/env lua
-- vim: set filetype=lua:
require 'Test.More'
local Version = require 'packagemanager/version'

plan(42)

local function canParse( rangeExpr, min, max )
    local range = Version.parseVersionRange(rangeExpr)
    is(range.min.major, min[1], 'can parse '..rangeExpr..': min.major')
    is(range.min.minor, min[2], 'can parse '..rangeExpr..': min.minor')
    is(range.min.patch, min[3], 'can parse '..rangeExpr..': min.patch')
    is(range.max.major, max[1], 'can parse '..rangeExpr..': max.major')
    is(range.max.minor, max[2], 'can parse '..rangeExpr..': max.minor')
    is(range.max.patch, max[3], 'can parse '..rangeExpr..': max.patch')
end

local function canCompose( rangeExpr )
    local range = Version.parseVersionRange(rangeExpr)
    is(tostring(range), rangeExpr, 'can compose '..rangeExpr)
end

local inf = math.huge

canParse('42',     {42,0,0}, {42,inf,inf})
canParse('42-43',  {42,0,0}, {43,inf,inf})
canParse('>42',    {42,0,1}, {inf,inf,inf})
canParse('>=42',   {42,0,0}, {inf,inf,inf})
canParse('<42',    {0,0,0},  {41,inf,inf})
canParse('<=42.0', {0,0,0},  {42,0,inf})

canCompose('42')
canCompose('42 - 43')
canCompose('> 42')
canCompose('>= 42')
canCompose('< 42')
canCompose('<= 42')

