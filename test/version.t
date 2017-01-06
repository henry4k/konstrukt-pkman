#!/usr/bin/env lua
-- vim: set filetype=lua:
require 'Test.More'
local Version = require 'packagemanager/version'

plan(114)

local function canParse( rangeExpr, min, max )
    local range = Version.parseVersionRange(rangeExpr)
    is(range.min.major, min[1], 'can parse '..rangeExpr..': min.major')
    is(range.min.minor, min[2], 'can parse '..rangeExpr..': min.minor')
    is(range.min.patch, min[3], 'can parse '..rangeExpr..': min.patch')
    is(range.max.major, max[1], 'can parse '..rangeExpr..': max.major')
    is(range.max.minor, max[2], 'can parse '..rangeExpr..': max.minor')
    is(range.max.patch, max[3], 'can parse '..rangeExpr..': max.patch')
end

local i = math.huge

canParse('*',      {0,0,0}, {i,i,i})
canParse('1',      {1,0,0}, {1,i,i})
canParse('1.2',    {1,2,0}, {1,2,i})
canParse('1.2.3',  {1,2,3}, {1,2,3})
canParse('~1.2.3', {1,2,3}, {1,2,i})
canParse('~1.2',   {1,2,0}, {1,2,i})
canParse('~1',     {1,0,0}, {1,i,i})
canParse('^1.2.3', {1,2,3}, {1,i,i})
canParse('^1.2',   {1,2,0}, {1,i,i})
canParse('^1.0.0', {1,0,0}, {1,i,i})
canParse('^0.1.2', {0,1,2}, {0,1,i})
canParse('^0.1',   {0,1,0}, {0,1,i})
canParse('^0.0.1', {0,0,1}, {0,0,1})
canParse('^0.0.0', {0,0,0}, {0,0,0})
canParse('2-3',    {2,0,0}, {3,i,i})
canParse('>2',     {2,0,1}, {i,i,i})
canParse('>=2',    {2,0,0}, {i,i,i})
canParse('<3',     {0,0,0}, {2,i,i})
canParse('<=3.0',  {0,0,0}, {3,0,i})
