#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local Markdown = require 'packagemanager/documentation/markdown'
local Heading = require 'packagemanager/documentation/Heading'

plan(7)


local function GetHeadings( markdownSource )
    local rootNode = Markdown.parse(markdownSource)
    local headingProcessor = Heading.createProcessor()
    Markdown.process(rootNode, {headingProcessor})
    return headingProcessor.headingTree,
           headingProcessor.headingList
end

local headingTree, headingList = GetHeadings([[
# aaa
## bbb
### ccc
## ddd
## eee
# eee
]])
is(#headingList, 6)
is(headingTree[1].name, 'aaa')
is(headingTree[1].children[1].name, 'bbb')
is(headingTree[1].children[3].name, 'eee')
is(headingTree[2].name, 'eee')

is(type(headingTree[1].fragmentId), 'string')
-- Must generate unique fragment ids, even if both headings have the same name:
isnt(headingTree[1].children[3].fragmentId,
     headingTree[2].fragmentId)
