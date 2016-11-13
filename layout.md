# Layout

## Config


```
{
    searchPaths = {...} -- Locations of where local packages can be found.
    -- Packages are installed to the first search path.
    repositories =
    {
        <name> = <index url>
    }
    requirements =
    {
        { -- A requirement group consists of ...
            <package name> = <version range>, -- requirements!
            ...
        },
        ...
    }
    repositoryCacheDir = ... -- defaults to 'repositories'
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

    -- Specific to executable packages:
    executables
    {
        <file name> =
        {
            install = true -- install executable
        },
        ...
    }

    -- Generated fields:
    required = ... -- if the package has been marked for installation by the user
    localFileName = ... -- if the package is currently installed
    downloadUrl = ... -- if the package can be downloaded
    virtual = true -- if package is provided by another package
    provider = ... -- providing package
}
```


## Job

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
