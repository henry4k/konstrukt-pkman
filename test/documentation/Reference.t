#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local Markdown = require 'packagemanager/documentation/markdown'
local Reference = require 'packagemanager/documentation/Reference'

plan(5)


local SourceDir
local function ToHtml( markdownSource )
    local rootNode = Markdown.parse(markdownSource)
    local referenceProcessor = Reference.createProcessor(SourceDir)
    Markdown.process(rootNode, {referenceProcessor})
    return Markdown.render(rootNode)
end


SourceDir = ''

-- Relative links are transformed correctly:
like(ToHtml('[aaa](aaa.md)'), 'href="aaa%.html"')
-- Title is correct:
like(ToHtml('[xxx](aaa.md)'), 'xxx')
-- External links are allowed:
like(ToHtml('[aaa](http://example.org)'), 'http://example%.org')
-- Only documents may be linked at the moment:
error_like(ToHtml, {'[aaa](aaa.png)'}, '.*')
-- References may not leave the package directory:
error_like(ToHtml, {'[aaa](aaa/../../bbb.md)'}, '.*')
