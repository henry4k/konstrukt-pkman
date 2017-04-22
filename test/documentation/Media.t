#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local Markdown = require 'packagemanager/documentation/markdown'
local Media = require 'packagemanager/documentation/Media'

plan(9)


local function ToHtml( markdownSource )
    local rootNode = Markdown.parse(markdownSource)
    local mediaProcessor = Media.createProcessor()
    Markdown.process(rootNode, {mediaProcessor})
    return Markdown.render(rootNode)
end

-- Images should generate an image tag:
like(ToHtml('![](aaa.png)'), '<img')
-- Only specific file types are supported:
error_like(ToHtml, {'![](aaa.md)'}, '.*')
-- Files may not be located outside the package directory:
error_like(ToHtml, {'![](/aaa.png)'}, '.*')
error_like(ToHtml, {'![](aaa/../../bbb.png)'}, '.*')
error_like(ToHtml, {'![](http://example.org/aaa.png)'}, '.*')


local function GetFileName( sourceDir, markdownSource )
    local rootNode = Markdown.parse(markdownSource)
    local mediaProcessor = Media.createProcessor(sourceDir)
    Markdown.process(rootNode, {mediaProcessor})
    return next(mediaProcessor.mediaFiles)
end

is(GetFileName('',    '![](aaa.png)'),     'aaa.png')
is(GetFileName('',    '![](aaa/bbb.png)'), 'aaa/bbb.png')
is(GetFileName('aaa', '![](bbb.png)'),     'aaa/bbb.png')
is(GetFileName('aaa', '![](../aaa.png)'),  'aaa.png')
