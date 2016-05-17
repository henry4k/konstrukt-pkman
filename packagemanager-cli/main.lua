local argparse = require 'argparse'
local utils = require 'packagemanager-cli/utils'
local Config = require 'packagemanager/config'
local Repository = require 'packagemanager/repository'
local PackageDB = require 'packagemanager/packagedb'

local function Run( commands )
    local parser = argparse()
    parser:option('-c --config', 'Configuration file', 'config.json')
    parser:command_target('command')
    for commandName, command in pairs(commands) do
        local subparser = parser:command(commandName, command.description)
        if command.setupParser then
            command.setupParser(subparser)
        end
    end
    local arguments = parser:parse()
    Config.load(arguments.config)
    commands[arguments.command].execute(arguments)
end

local commands = {}
commands.list =
{
    description = 'Print packages.',

    execute = function()
        local db = utils.buildPackageDB{localPackages=true, remotePackages=true}
        utils.markUserRequirements(db)
        for package in PackageDB.packages(db) do
            local status = utils.getPackageInstallationStatus(package)
            print(string.format('%s %s %s', package.name, tostring(package.version), status))
        end
    end
}
commands.update =
{
    description = 'Synchronize package lists, install stuff.',

    execute = function()
        utils.updateRepos()
        local db = utils.buildPackageDB{localPackages=true, remotePackages=true}
        utils.installRequirements(db)
    end
}
commands.index =
{
    description = 'Generate a package index.  Needed for repositories.',

    setupParser = function( parser )
        parser:argument('baseUrl', '')
            :args(1)
        parser:argument('file', 'Index location', 'index.json')
            :args(1)
    end,

    execute = function( arguments )
        local db = utils.buildPackageDB{localPackages=true}
        Repository.saveIndexToFile(db, arguments.file, arguments.baseUrl)
    end
}

Run(commands)
