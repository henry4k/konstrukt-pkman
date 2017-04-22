#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local cmark = require 'cmark'
local Markdown = require 'packagemanager/documentation/markdown'

plan(1)


local rootNode = Markdown.parse([[
# *aaa*
]])
local h1Node = cmark.node_first_child(rootNode)
is(Markdown.renderChildren(h1Node), '<em>aaa</em>')
