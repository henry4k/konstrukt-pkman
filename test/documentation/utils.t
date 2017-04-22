#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local Utils = require 'packagemanager/documentation/utils'

plan(4)


nok(Utils.isUrlLocalPath('http://example.org'))
ok(Utils.isUrlLocalPath('aaa/bbb/../ccc.png'))
ok(Utils.isUrlLocalPath('/aaa/bbb/../ccc.png'))

is(Utils.stripHtmlTags('a<div>b</div>c'), 'abc')
