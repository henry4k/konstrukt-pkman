#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'
local UnixPath    = require('packagemanager/path').unix
local WindowsPath = require('packagemanager/path').windows

plan(28)

do
    local info = UnixPath.parseFileName('baz')
    is(info.path, nil, 'parseFileName: path')
    is(info.baseName, 'baz', 'parseFileName: baseName')
    is(info.extension, nil, 'parseFileName: extension')
end

do
    local info = UnixPath.parseFileName('/foo/bar/baz')
    is(info.path, '/foo/bar', 'parseFileName: path')
    is(info.baseName, 'baz', 'parseFileName: baseName')
    is(info.extension, nil, 'parseFileName: extension')
end

do
    local info = UnixPath.parseFileName('./../baz')
    is(info.path, './..', 'parseFileName: path')
    is(info.baseName, 'baz', 'parseFileName: baseName')
    is(info.extension, nil, 'parseFileName: extension')
end

do
    local info = WindowsPath.parseFileName('C:\\foo\\bar\\baz.exe')
    is(info.path, 'C:\\foo\\bar', 'parseFileName: path')
    is(info.baseName, 'baz', 'parseFileName: baseName')
    is(info.extension, 'exe', 'parseFileName: extension')
end

is(UnixPath.dirName('/aaa/bbb/ccc'), '/aaa/bbb', 'dirname: unix path')
is(WindowsPath.dirName('C:\\aaa\\bbb\\ccc'), 'C:\\aaa\\bbb', 'dirname: windows path')

is(UnixPath.baseName('/aaa/bbb/ccc'), 'ccc', 'basename: unix path')
is(WindowsPath.baseName('C:\\aaa\\bbb\\ccc'), 'ccc', 'basename: windows path')

is(UnixPath.extension('aaa.bbb.ccc'), 'ccc', 'extension')
is(UnixPath.extension('aaa.bbb/ccc'), nil, 'extension')

is(UnixPath.stripExtension('aaa.bbb.ccc'), 'aaa.bbb', 'stripExtension')
is(UnixPath.stripExtension('aaa.bbb/ccc'), 'aaa.bbb/ccc', 'stripExtension')

is(UnixPath.canonicalize('aaa/bbb/ccc'), 'aaa/bbb/ccc')
is(UnixPath.canonicalize('aaa/../ccc'), 'ccc')
is(UnixPath.canonicalize('aaa/../ccc/..'), '')
is(UnixPath.canonicalize('aaa/./ccc'), 'aaa/ccc')
is(UnixPath.canonicalize('././aaa'), 'aaa')
is(UnixPath.canonicalize('aaa/../../..'), '../..')

is(UnixPath.resolveRelative('ccc', 'aaa/bbb'), 'aaa/bbb/ccc')
is(UnixPath.resolveRelative('../ccc', 'aaa/bbb'), 'aaa/ccc')
