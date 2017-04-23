#!/usr/bin/env lua
-- vim: set filetype=lua:
dofile 'test/common.lua'

local PackageDB = require 'packagemanager/PackageDB'
local semver = require 'semver'

local function try( name, fn )
    lives_ok(fn, {}, name)
end


do
    local db = PackageDB()
    local package = {name = 'aaa',
                     type = 'regular',
                     version = semver('1.2.3')}

    try('package can be added', function()
        db:addPackage(package)
    end)

    is(db:gatherPackages{name = 'aaa'}[1], package,
       'package can be found')

    db:removePackage(package)
    is(#db:gatherPackages{name = 'aaa'}, 0,
       'package can be removed')
end
