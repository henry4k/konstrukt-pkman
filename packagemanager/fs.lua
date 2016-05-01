local cjson = require 'cjson'
local semver = require 'semver'



local FS = {}

FS.dirSep = '/'

function FS.path( ... )
    return table.concat({...}, FS.dirSep)
end

function FS.readFile( fileName )
    local file = assert(io.open(fileName, 'r'))
    local content = file:read('*a')
    file:close()
    return content
end

function FS.readJsonFile( fileName )
    return cjson.decode(FS.readFile(fileName))
end

function FS.writeFile( fileName, content )
    local file = assert(io.open(fileName, 'w'))
    file:write(content)
    file:close()
end

function FS.writeJsonFile( fileName, value )
    return FS.writeFile(fileName, cjson.encode(value))
end

function FS.parseFileName( fileName )
    local path, pathEnd = fileName:match('^(.*)[/\\]()')
    pathEnd = pathEnd or 1
    local extensionStart, extension = fileName:match('()%.([^.]*)$', pathEnd)
    extensionStart = extensionStart or 0
    local baseName = fileName:sub(pathEnd, extensionStart-1)
    return {path=path, baseName=baseName, extension=extension}
end

function FS.parsePackageFileName( fileName )
    local result, err = FS.parseFileName(fileName)
    if not result then
        return nil, err
    end

    local baseName = result.baseName
    if not baseName or #baseName == 0 then
        return nil, 'No base name.'
    end

    local package, packageEnd = baseName:match('^([^.]+)()')
    if not package then
        return nil, 'No package name.'
    end
    result.package = package

    local version = baseName:match('^%.(.+)', packageEnd)
    if version then
        local success, resultOrErr = pcall(semver, version)
        if not success then
            return nil, resultOrErr
        end
        result.version = resultOrErr
    end

    return result
end


return FS
