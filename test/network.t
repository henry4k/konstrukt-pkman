#!/usr/bin/env lua
-- vim: set filetype=lua:
require 'test/common'
local Mock = require 'test.mock.Mock'

local lfs = { attributes = Mock() }
local http = { request = Mock() }
FakeRequire:fakeModule('lfs', lfs)
FakeRequire:fakeModule('socket.http', http)
FakeRequire:install()

local network = require 'network'


plan(1)

network.downloadFile('')
