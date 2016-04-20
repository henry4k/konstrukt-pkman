#!/usr/bin/env lua
-- vim: set filetype=lua:
require 'test/common'
local fs = require 'fs'

plan(16)

do
    local info = fs.parseFileName('baz')
    is(info.path, nil, 'parseFileName: path')
    is(info.baseName, 'baz', 'parseFileName: baseName')
    is(info.extension, nil, 'parseFileName: extension')
end

do
    local info = fs.parseFileName('/foo/bar/baz')
    is(info.path, '/foo/bar', 'parseFileName: path')
    is(info.baseName, 'baz', 'parseFileName: baseName')
    is(info.extension, nil, 'parseFileName: extension')
end

do
    local info = fs.parseFileName('./../baz')
    is(info.path, './..', 'parseFileName: path')
    is(info.baseName, 'baz', 'parseFileName: baseName')
    is(info.extension, nil, 'parseFileName: extension')
end

do
    local info = fs.parseFileName('C:\\foo\\bar\\baz.exe')
    is(info.path, 'C:\\foo\\bar', 'parseFileName: path')
    is(info.baseName, 'baz', 'parseFileName: baseName')
    is(info.extension, 'exe', 'parseFileName: extension')
end

do
    local info = fs.parsePackageFileName('foobar.1.2.3.zip')
    is(info.package, 'foobar', 'parsePackageFileName: package')
    is(tostring(info.version), '1.2.3', 'parsePackageFileName: version')
end

do
    local info = fs.parsePackageFileName('foobar.zip')
    is(info.package, 'foobar', 'parsePackageFileName: package')
    is(info.version, nil, 'parsePackageFileName: version')
end
