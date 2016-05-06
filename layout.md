# Layout

## Package

An actual installable package.

```
{
    -- Required fields:
    name = ... -- Usually not needed in serialized form.
    type = ... -- regular, scenario, packagemanager, engine, native
    version = {...}
    dependencies =
    {
        <package name> = <version range>
    }

    -- :
    required = ... -- if the package has been marked for installation by the user
    localFileName = ... -- if the package is currently installed
    downloadUrl = ... -- if the package can be downloaded
}
```




## Package index

Stores packages.  Since packages can be available in multiple versions,
the index stores the package versions `index[<package name>]`.

```
{
    <package name> = -- Package versions
    {
        <version string> = {<package>}
    }
}
```
