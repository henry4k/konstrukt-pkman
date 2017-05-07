#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local RingBuffer = require 'packagemanager-cli/RingBuffer'

plan(20)

do
    note('Basic properties:')
    local buffer = RingBuffer(10)
    is(#buffer, 0, 'empty buffer is empty')
    buffer:append('aaa')
    is(buffer[1], 'aaa', 'can store one element')
    is(#buffer, 1, 'increases size')
    is(buffer[0],  nil, 'out of range is correctly handled (0)')
    is(buffer[-1], nil, 'out of range is correctly handled (-1)')
    is(buffer[2],  nil, 'out of range is correctly handled (2)')
end

do
    note('Buffer with size of 10 gets 10 elements:')
    local buffer = RingBuffer(10)
    for i = 1, 10 do
        buffer:append('element '..i)
    end
    is(#buffer, 10, 'buffer is full')
    is(buffer[1], 'element 1', 'first element is correct')
    is(buffer[10], 'element 10', 'last element is correct')
end

do
    note('Buffer with size of 10 gets more than 10 elements:')
    local buffer = RingBuffer(10)
    for i = 1, 11 do
        buffer:append('element '..i)
    end
    is(#buffer, 10, 'buffer is full')
    is(buffer[1], 'element 2', 'first element is correct')
    is(buffer[10], 'element 11', 'last element is correct')
    buffer:append('element 12')
    is(#buffer, 10, 'buffer is still full')
    is(buffer[1], 'element 3', 'first element is correct')
    is(buffer[10], 'element 12', 'last element is correct')

    local r = {}
    for i, v in ipairs(buffer) do
        table.insert(r, {i = i, v = v})
    end
    is(#r, 10, 'iterator generates correct amount of results')
    is(r[1].i, 1, 'iterator starts with 1')
    is(r[1].v, 'element 3', 'iterator starts with correct value')
    is(r[10].i, 10, 'iterator ends with 10')
    is(r[10].v, 'element 12', 'iterator ends with correct value')
end
