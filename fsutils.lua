local cjson = require 'cjson'
local semver = require 'semver'



local fsutils = {}

fsutils.dirSep = '/'

function fsutils.path( ... )
    return table.concat({...}, fsutils.dirSep)
end

function fsutils.readFile( fileName )
    local file = assert(io.open(fileName, 'r'))
    local content = file:read('*a')
    file:close()
    return content
end

function fsutils.readJsonFile( fileName )
    return cjson.decode(fsutils.readFile(fileName))
end

function fsutils.parseFileName( fileName )
    local path, pathEnd = fileName:match('^(.*)[/\\]()')
    pathEnd = pathEnd or 1
    local extensionStart, extension = fileName:match('()%.([^.]*)$')
    extensionStart = extensionStart or 0
    local baseName = fileName:sub(pathEnd, extensionStart-1)
    return {path=path, baseName=baseName, extension=extension}
end

function fsutils.parsePackageFileName( fileName )
    local result, err = fsutils.parseFileName(fileName)
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


return fsutils
