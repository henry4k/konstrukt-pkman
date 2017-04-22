local Path     = require('packagemanager/path').windows
local Markdown = require 'packagemanager/documentation/markdown'


local DocumentTypes =
{
    md =
    {
        parser = function( fileContent )
            return Markdown.parse(fileContent)
        end
    },

    lua =
    {
        parser = function()
            error('Parsing Lua is not supported yet.')
        end
    }
}

local function GetDocumentType( extension )
    return DocumentTypes[extension]
end

local function IterDocuments( sourceTree )
    return coroutine.wrap(function()
        for filePath in sourceTree:eachFile() do
            local extension = Path.extension(filePath)
            local documentType = GetDocumentType(extension)
            if documentType then
                local file = sourceTree:openFile(filePath, 'r')
                local fileContent = file:read('*a')
                file:close()
                local rootNode = documentType.parser(fileContent)
                coroutine.yield(filePath, rootNode)
            end
        end
    end)
end

return { getType = GetDocumentType,
         iterSourceTree = IterDocuments }
