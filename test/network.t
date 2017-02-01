#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local Mock = require 'test.mock.Mock'
local FakeRequire = require 'test/FakeRequire'

--local lfs = { attributes = Mock() }
--local http = { request = Mock() }
--FakeRequire:fakeModule('lfs', lfs)
--FakeRequire:fakeModule('socket.http', http)
--FakeRequire:install()
--
--local network = require 'network'
--
--
plan(1)
ok(true)
--
--network.downloadFile('')
