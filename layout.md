# Layout

## Config


```
{
    searchPaths = -- Locations which are used to discover local packages
                  -- defaults to { 'packages' }
    {
        -- the first entry is also used to install packages
    }
    -- Packages are installed to the first search path.
    repositories = -- Index URLs of repositories
                   -- defaults to {} (Will change in the future!)
    {
        ...
    }
    requirements =
    {
        { -- A requirement group consists of ...
            <package name> = <version range>, -- requirements!
            ...
        },
        ...
    }
    manager = -- defines which package manager shall be used
    {
        name = <package name>
        versionRange = <version range>
    }
    repositoryCacheDir = ... -- defaults to 'repositories'
    documentationCacheDir = ... -- defaults to 'documentation'
}
```


## Package

An actual installable package.

```
{
    -- Required fields:
    name = ... -- Usually not needed in serialized form.
    type = ... -- regular, scenario, native, engine, package-manager

    version = {...} -- optional for local packages

    -- Optional fields:
    date = ...
    description = ...
    dependencies =
    {
        <package name> = <version range>
    }
    provides =
    {
        <package name> = <version>
    }

    -- Specific to packagemanager, engine and native packages:
    operatingSystem = ... -- windows, linux, macosx, ...
    architecture = ... -- x86, x86_64, ...

    -- Specific to engine and package-manager packages:
    mainExecutables = -- these are the "entry points" to the engine or package manager
    {
        <file name> =
        {
            headless = true -- does not need a gui (defaults to false)
            debug    = true -- executable has debug symbols (defaults to false)
        }
        ...
    }

    -- Fields which are present in indices:
    size = ... -- in bytes

    -- Generated fields:
    required = ... -- if the package has been marked for installation by the user
    localFileName = ... -- if the package is currently installed
    downloadUrl = ... -- if the package can be downloaded
    virtual = true -- if package is provided by another package
    provider = ... -- providing package
}
```


## Task

```
{
    typeName = ...
    eventHandler = {}
    status = [waiting, running, success, fail]
    properties = {}
}
```


## Change

```
{
    type = [install, uninstall]
    eventHandler = {}
    package = ...
}
```
