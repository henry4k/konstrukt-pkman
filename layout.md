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
}
```


## Package

An actual installable package.

```
{
    -- Required fields:
    name = ... -- Usually not needed in serialized form.
    type = ... -- regular, scenario, packagemanager, engine, native
    version = {...}

    -- Optional fields:
    dependencies =
    {
        <package name> = <version range>
    }
    provides =
    {
        <package name> = <version>
    }

    -- Specific to packagmanager packages:
    executables =
    {
        <file name>,
        ...
    }

    -- Generated fields:
    required = ... -- if the package has been marked for installation by the user
    localFileName = ... -- if the package is currently installed
    downloadUrl = ... -- if the package can be downloaded
}
```
