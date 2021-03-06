local argparse = require 'argparse'
local lanes = require 'packagemanager/lanes'
local PackageManager = require 'packagemanager/init'
local Repository = require 'packagemanager/repository'
local utils = require 'packagemanager-cli/utils'
local ProcessChangeTasks = require('packagemanager-cli/changes').processChangeTasks


local function Run( commands )
    local parser = argparse()
    parser{name = 'pkman',
           description = 'A package manager for the konstrukt engine.',
           epilog = 'For more info, see https://github.com/henry4k/konstrukt-pkman'}
    parser:option('-c --config', 'Configuration file;  Using this disables the automatic setup and modification of the configuration.')
    parser:command_target('command')
    for commandName, command in pairs(commands) do
        local subparser = parser:command(commandName, command.description)
        if command.setupParser then
            command.setupParser(subparser)
        end
    end
    local arguments = parser:parse()
    PackageManager.initialize(arguments.config)
    commands[arguments.command].execute(arguments)
    PackageManager.finalize()
end

local commands = {}
commands.version =
{
    description = 'Show package manager version.',

    execute = function( arguments )
        local info, err = PackageManager.getInfo()
        if info then
            print(string.format('%s %s',
                                info.name,
                                tostring(info.version or '')))
        else
            io.stderr:write('Unable to obtain version information: ', err, '\n')
        end
    end
}
commands.query =
{
    description = 'Search and print packages.',

    setupParser = function( parser )
        parser:argument('query', '', '')
            :args(1)
    end,

    execute = function( arguments )
        local packages = PackageManager.searchWithQueryString(arguments.query)
        for _, package in pairs(packages) do
            local status = utils.getPackageInstallationStatus(package)
            print(string.format('%s %s %s', package.name, tostring(package.version), status))
        end
    end
}
commands.update =
{
    description = 'Download package indices.',

    execute = function()
        local tasks = PackageManager.updateRepositoryIndices()
        for _, task in pairs(tasks) do
            task:start()
        end
        repeat
            lanes.sleep(1/25)
            PackageManager.update()
            local complete = true
            for _, task in pairs(tasks) do
                if task.status == 'running' or
                   task.status == 'unstarted' then
                   complete = false
               end
            end
        until complete
    end
}
commands['list-changes'] =
{
    description = 'Show changes.',

    execute = function()
        local changes = PackageManager.gatherChanges()
        for _, change in pairs(changes) do
            local package = change.package
            local changeType
            if change.type == 'install' then
                changeType = '+'
            else
                changeType = '-'
            end
            print(string.format('%s %s %s',
                                changeType,
                                package.name,
                                tostring(package.version)))
        end
    end
}
commands.upgrade =
{
    description = 'Install and remove packages.',

    execute = function()
        local changes = PackageManager.gatherChanges()
        local tasks = PackageManager.applyChanges(changes)
        ProcessChangeTasks(tasks)
    end
}
commands['generate-index'] =
{
    description = 'Generate a package index.  Needed for repositories.',

    setupParser = function( parser )
        parser:argument('baseUrl', '')
            :args(1)
        parser:argument('file', 'Index location', 'index.json')
            :args(1)
    end,

    execute = function( arguments )
        PackageManager.buildPackageDB{localPackages=true}
        local db = PackageManager.getPackageDB()
        Repository.saveIndexToFile(db, arguments.file, arguments.baseUrl)
    end
}
--[[
commands.run =
{
    description = 'Start the given scenario using an appropriate engine.',

    setupParser = function( parser )
        parser:argument('scenario', '')
            :args(1)
        --parser:argument('package', 'Additional packages.')
        --    :args('*')
    end,

    execute = function( arguments )
        local scenarioName = arguments.scenario
        PackageManager.launchScenario(scenario)
    end
}
]]

Run(commands)
