local path      = require 'path'
local lustache  = require 'lustache'
local FS        = require 'packagemanager/fs'
local Config    = require 'packagemanager/config'
local PackageManager = require 'packagemanager/init'
local Package   = require 'packagemanager/package'
local TreeView  = require 'packagemanager/TreeView'
local Utils     = require 'packagemanager/documentation/utils'
local Markdown  = require 'packagemanager/documentation/markdown'
local Document  = require 'packagemanager/documentation/Document'
local Heading   = require 'packagemanager/documentation/Heading'
local Media     = require 'packagemanager/documentation/Media'
local Reference = require 'packagemanager/documentation/Reference'


local Documentation = {}

local function RenderDocument( templateHtml,
                               rootNode,
                               headingTree )
    local contentHtml = Markdown.render(rootNode)
    local title = headingTree[1].name

    local model =
    {
        title = Utils.stripHtmlTags(title),
        menu =
        {
            { name = 'Showcase', url = '' },
            { name = 'Downloads', url = '' },
            { name = 'Packages', url = '' }
        },
        content = contentHtml,
        index = headingTree[1].children
    }

    return lustache:render(templateHtml, model)
end

local function Generate( sourceTree, resultTree )
    local mediaFiles = {}
    local templateHtml = FS.readFile(FS.here('template.html'))

    for sourceFileName, rootNode in Document.iterSourceTree(sourceTree) do
        local sourceDir = path.dirname(sourceFileName)

        local headingProcessor = Heading.createProcessor()
        local referenceProcessor = Reference.createProcessor(sourceDir)
        local mediaProcessor = Media.createProcessor(sourceDir)

        Markdown.process(rootNode, { headingProcessor,
                                     referenceProcessor,
                                     mediaProcessor })

        Media.addMediaFiles(mediaFiles, mediaProcessor.mediaFiles)

        -- Generate HTML:
        local html = RenderDocument(templateHtml,
                                    rootNode,
                                    headingProcessor.headingTree)
        local resultFileName = path.splitext(sourceFileName)..'.html'
        local resultFile = resultTree:openFile(resultFileName, 'w')
        resultFile:write(html)
        resultFile:close()
    end

    Media.processMediaFiles(mediaFiles, sourceTree, resultTree)
end

local function ResolveVirtualPackage( package )
    if package.providerId then
        local db = PackageManager.getPackageDB()
        package = assert(db:getPackageById(package.providerId))
    end
    return package
end

function Documentation.generate( package )
    package = ResolveVirtualPackage(package)

    assert(package.localFileName,
           'Documentation can only be generated for installed packages.')

    local baseName = Package.buildBaseName(package.name, package.version)
    FS.makeDirectoryPath(Config.documentationCacheDir, baseName)
    local resultPath = path.join(Config.documentationCacheDir, baseName)

    local sourceTree = TreeView(package.localFileName)
    local resultTree = TreeView(resultPath)
    Generate(sourceTree, resultTree)

    return resultPath
end

function Documentation.canGenerate( package )
    package = ResolveVirtualPackage(package)
    return package.localFileName ~= nil
end

----- Remove all generated documentation.
--function Documentation.clear()
--end


return Documentation
