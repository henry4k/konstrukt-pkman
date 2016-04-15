# Layout

## Package

An actual installable package.

```
{
    -- Required fields:
    name = ... -- Usually not needed in serialized form.
    version = {...},
    dependencies = {...}

    -- :
    selected = ... -- if the package has been marked for installation by the user
    localFileName = ... -- if the package is currently installed
}
```




## Package DB

Stores packages.  Since packages can be available in multiple versions,
the DB stores the package versions `db[<package name>]`.

```
{
    <package name> =
    {
        <version string> = {<package>}
    }
}
```
