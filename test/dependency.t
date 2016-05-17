#!/usr/bin/env lua
-- vim: set filetype=lua:
require 'Test.More'
local semver = require 'semver'
local Version    = require 'packagemanager/version'
local Repository = require 'packagemanager/repository'
local Dependency = require 'packagemanager/dependency'
local PackageDB = require 'packagemanager/packagedb'


local function testResolver( name, indexFileName, dependencies, expectedPackages )
    local db = PackageDB.create()
    Repository.loadIndexFromFile(db, indexFileName)

    -- Refine arguments:
    for packageName, versionRangeStr in pairs(dependencies) do
        dependencies[packageName] = Version.parseVersionRange(versionRangeStr)
    end
    for packageName, versionStr in pairs(expectedPackages) do
        expectedPackages[packageName] = semver(versionStr)
    end

    local packages
    lives_ok(function() packages = Dependency.resolve(db, dependencies) end, {}, name..': resolve')

    -- Check for expected packages:
    for packageName, version in pairs(expectedPackages) do
        local package = packages[packageName]
        ok(package, string.format('%s: has package %s', name, packageName))
        is(package.version, version, string.format('%s: %s is at %s', name, packageName, versionStr))
    end

    -- Check for superfluous packages:
    local superfluous = false
    for packageName, _ in pairs(packages) do
        if not packages[packageName] then
            superfluous = true
            diag(string.format('package %s was not expected', packageName))
        end
    end
    ok(not superfluous, name..': no superfluous packages')
end


plan(16)
testResolver('simple', 'test/simple.json', {A='1'}, {A='1', B='2', C='2'})
testResolver('cyclic', 'test/cyclic.json', {A='1'}, {A='1', B='2', C='2'})
