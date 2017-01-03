local lfs = require 'lfs'
local cjson = require 'cjson'
local semver = require 'semver'
local Misc      = require 'packagemanager/misc'
local FS        = require 'packagemanager/fs'
local Zip       = require 'packagemanager/zip'
local Version   = require 'packagemanager/version'
local PackageDB = require 'packagemanager/packagedb'
local Config    = require 'packagemanager/config'
local Package   = require 'packagemanager/package'


local LocalPackage = {}

local function ExtractPackageMetadata( fileName )
    local fileType = lfs.attributes(fileName, 'mode')
    if not fileType then
        error('File not found.')
    elseif fileType == 'directory' then
        return assert(FS.readJsonFile(FS.path(fileName, 'package.json')))
    else
        if fileName:match('%.zip$') then
            return cjson.decode(assert(Zip.readFile(fileName, 'package.json')))
        else
            error('Not a package: '..fileName)
        end
    end
end

local function PreprocessMetaData( metadata )
    metadata.version = semver(metadata.version or 0)

    if metadata.dependencies then
        for package, versionRange in pairs(metadata.dependencies) do
            assert(type(versionRange) == 'string')
            metadata.dependencies[package] =
                Version.parseVersionRange(versionRange)
        end
    end

    if metadata.provides then
        for name, version in pairs(metadata.provides) do
            assert(type(name) == 'string')
            assert(type(version) == 'string')
            metadata.provides[name] = semver(version)
        end
    end
end

local LocalPackageMT = {}
function LocalPackageMT.__index( package, key )
    if not package._metadataLoaded then
        package._metadataLoaded = true
        local metadata = ExtractPackageMetadata(package.localFileName)
        PreprocessMetaData(metadata)
        Package.mergePackages(package, metadata)
        return package[key]
    end
end

function LocalPackage.readLocalPackage( fileName )
    -- See 
    local packageInfo = assert(FS.parsePackageFileName(fileName))
    local package =
    {
        name = packageInfo.package,
        version = packageInfo.version,
        localFileName = fileName,
        _metadataLoaded = false
    }
    return setmetatable(package, LocalPackageMT)
end

local function IsLocalPackage( fileName )
    local mode = lfs.attributes(fileName, 'mode')
    if mode == 'directory' then
        local metaFileName = FS.path(fileName, 'package.json')
        return lfs.attributes(metaFileName, 'mode') == 'file'
    elseif mode == 'file' then
        return fileName:match('%.zip$')
    end
end

function LocalPackage.gatherInstalledPackages( db, searchPaths )
    local packages = {}
    for _, searchPath in ipairs(searchPaths) do
        for entry in lfs.dir(searchPath) do
            local fileName = FS.path(searchPath, entry)
            local fileInfo = FS.parsePackageFileName(fileName)
            if fileInfo and IsLocalPackage(fileName) then
                local baseName = Package.buildBaseName(fileInfo.package,
                                                       fileInfo.version)
                if not packages[baseName] then
                    packages[baseName] = LocalPackage.readLocalPackage(fileName)
                end
            end
        end
    end

    for _, package in pairs(packages) do
        PackageDB.addPackage(db, package)
    end
end

local function PropertyMatchesComparator( property, comparator )
    if type(comparator) == 'function' then
        return comparator(property)
    else
        return property == comparator
    end
end

local function ExecutableMatchesComparators( attributes, comparators )
    for propertyName, comparator in pairs(comparators) do
        local property = attributes[propertyName]
        if not PropertyMatchesComparator(property, comparator) then
            return false
        end
    end
    return true
end

function LocalPackage.getMainExecutable( package, comparators )
    for executable, attributes in pairs(package.mainExecutables or {}) do
        if ExecutableMatchesComparators(attributes, comparators) then
            return executable
        end
    end
end

local function GetLauncherFileName( launcherBaseName )
    if Misc.os == 'windows' then
        return FS.path(Config.baseDir, launcherBaseName)..'.bat'
    else
        return FS.path(Config.baseDir, launcherBaseName)
    end
end

local UnixLauncherTemplate = [[
#!/bin/sh
'%s' --config '%s' $@
]]

local WindowsLauncherTemplate = [[
@echo off
'%s' --config '%s' %%*
]]

local function CreateLauncher( launcherFileName, executableFileName )
    local launcherFile = assert(io.open(launcherFileName, 'w'))
    if Misc.os == 'windows' then
        launcherFile:write(string.format(WindowsLauncherTemplate,
                                         executableFileName,
                                         Config.fileName))
        launcherFile:close()
    else
        launcherFile:write(string.format(UnixLauncherTemplate,
                                         executableFileName,
                                         Config.fileName))
        launcherFile:close()
        os.execute(string.format('chmod +x "%s"', launcherFileName))
    end
end

local LauncherEnabledPackage

function LocalPackage.allowLauncherFor( package )
    LauncherEnabledPackage = package
end

local function UpdateLauncher( name, package, executable )
    local launcherFileName = GetLauncherFileName(name)
    if executable then
        local executableFileName = FS.path(package.localFileName, executable)
        CreateLauncher(launcherFileName, executableFileName)
    else
        os.remove(launcherFileName)
    end
end

local function Falsy(v) return not v end

function LocalPackage.setup( package )
    if package == LauncherEnabledPackage then
        assert(package.type == 'package-manager')
        UpdateLauncher('pkman',     package, LocalPackage.getMainExecutable(package, {headless = true}))
        UpdateLauncher('pkman-gui', package, LocalPackage.getMainExecutable(package, {headless = Falsy}))
    end
end

function LocalPackage.teardown( package )
    -- Temporarily disabled as it is unknown which package owns the launcher.
    -- TODO: How to obtain the owner?
end

function LocalPackage.remove( db, package )
    assert(package.localFileName, 'File name missing - maybe package is not an installed package?')
    LocalPackage.teardown(package)
    assert(FS.recursiveDelete(package.localFileName))

    -- Remove any evidence that this was a local package once:
    assert(getmetatable(package) == LocalPackageMT)
    setmetatable(package, nil)
    package.localFileName = nil
    package._metadataLoaded = nil
    -- This seems to be all we can do here.
    -- The only accurate alternative seems to be
    -- rebuilding the database completly.
end

local function BuildSystemCommand( arguments )
    local buffer = {}
    for _, argument in ipairs(arguments) do
        table.insert(buffer, '"'..tostring(argument)..'"')
    end
    return table.concat(buffer, ' ')
end

function LocalPackage.launchEngine( engine,
                                    executableComparators,
                                    scenario,
                                    otherPackages )
    assert(engine.type == 'engine', 'Package is not an engine package.')
    assert(engine.localFileName, 'Engine seems not to be installed.')

    local executable = LocalPackage.getMainExecutable(engine, executableComparators)
    assert(executable, 'No suitable executable found.')

    local executableFileName = FS.path(engine.localFileName, executable)
    local state = ''
    local sharedState = ''
    local searchPaths = Config.searchPaths

    local arguments = {executableFileName,
                       '--state='..state,
                       '--shared-state='..sharedState,
                       '--search-paths='..table.concat(searchPaths, ';')}
    table.insert(arguments, scenario.name)
    for _, package in ipairs(otherPackages) do
        table.insert(arguments, package.name)
    end

    local command = BuildSystemCommand(arguments)
    print(command)
    --assert(os.execute(command))
end


return LocalPackage
