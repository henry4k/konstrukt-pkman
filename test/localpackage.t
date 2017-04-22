#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local LocalPackage = require 'packagemanager/localpackage'

plan(4)

do
    local info = LocalPackage.parsePackageFileName('foobar.1.2.3.zip')
    is(info.package, 'foobar', 'parsePackageFileName: package')
    is(tostring(info.version), '1.2.3', 'parsePackageFileName: version')
end

do
    local info = LocalPackage.parsePackageFileName('foobar.zip')
    is(info.package, 'foobar', 'parsePackageFileName: package')
    is(info.version, nil, 'parsePackageFileName: version')
end
