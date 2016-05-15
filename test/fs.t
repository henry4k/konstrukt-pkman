#!/usr/bin/env lua
-- vim: set filetype=lua:
require 'Test.More'
local FS = require 'packagemanager/fs'

plan(24)

do
    local info = FS.parseFileName('baz')
    is(info.path, nil, 'parseFileName: path')
    is(info.baseName, 'baz', 'parseFileName: baseName')
    is(info.extension, nil, 'parseFileName: extension')
end

do
    local info = FS.parseFileName('/foo/bar/baz')
    is(info.path, '/foo/bar', 'parseFileName: path')
    is(info.baseName, 'baz', 'parseFileName: baseName')
    is(info.extension, nil, 'parseFileName: extension')
end

do
    local info = FS.parseFileName('./../baz')
    is(info.path, './..', 'parseFileName: path')
    is(info.baseName, 'baz', 'parseFileName: baseName')
    is(info.extension, nil, 'parseFileName: extension')
end

do
    local info = FS.parseFileName('C:\\foo\\bar\\baz.exe')
    is(info.path, 'C:\\foo\\bar', 'parseFileName: path')
    is(info.baseName, 'baz', 'parseFileName: baseName')
    is(info.extension, 'exe', 'parseFileName: extension')
end

do
    local info = FS.parsePackageFileName('foobar.1.2.3.zip')
    is(info.package, 'foobar', 'parsePackageFileName: package')
    is(tostring(info.version), '1.2.3', 'parsePackageFileName: version')
end

do
    local info = FS.parsePackageFileName('foobar.zip')
    is(info.package, 'foobar', 'parsePackageFileName: package')
    is(info.version, nil, 'parsePackageFileName: version')
end

is(FS.dirName('/aaa/bbb/ccc'), '/aaa/bbb', 'dirname: unix path')
is(FS.dirName('C:\\aaa\\bbb\\ccc'), 'C:\\aaa\\bbb', 'dirname: windows path')

is(FS.baseName('/aaa/bbb/ccc'), 'ccc', 'basename: unix path')
is(FS.baseName('C:\\aaa\\bbb\\ccc'), 'ccc', 'basename: windows path')

is(FS.extension('aaa.bbb.ccc'), 'ccc', 'extension')
is(FS.extension('aaa.bbb/ccc'), nil, 'extension')

is(FS.stripExtension('aaa.bbb.ccc'), 'aaa.bbb', 'stripExtension')
is(FS.stripExtension('aaa.bbb/ccc'), 'aaa.bbb/ccc', 'stripExtension')
