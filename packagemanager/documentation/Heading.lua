local cmark    = require 'cmark'
local Utils    = require 'packagemanager/documentation/utils'
local Markdown = require 'packagemanager/documentation/markdown'


local Processor = {}
Processor.__index = Processor
Processor.nodeFilter = {cmark.NODE_HEADING}

local function MakeFragmentId( str )
    str = string.lower(str)
    str = string.gsub(str, '%s', '-')
    str = string.gsub(str, '[^a-z0-9]', '-')
    str = string.gsub(str, '%-+', '-')
    str = string.match(str, '^%-*(.-)%-*$') -- trim - from start and end
    return str
end

function Processor:_makeUniqueFragmentId( headingName )
    local ids = self._usedFragmentIds
    local id = MakeFragmentId(Utils.stripHtmlTags(headingName))

    -- Ensure a unique id:
    if ids[id] then
        local i = 1
        while ids[id..'-'..tostring(i)] do
            i = i + 1
        end
        id = id..'-'..tostring(i)
    end

    ids[id] = true

    return id
end

local function CreateFragmentNode( headingNode, fragmentId )
    local fragmentNode = cmark.node_new(cmark.NODE_CUSTOM_INLINE)
    cmark.node_set_on_enter(fragmentNode, string.format('<a href="#%s" id="%s" title="Permalink" class="fragment">', fragmentId, fragmentId))
    cmark.node_set_on_exit(fragmentNode, '</a>')
    assert(cmark.node_append_child(headingNode, fragmentNode))
end

local function CreateEmptyHeading()
    return { children = {} }
end

local function AddHeading( tree, level, heading )
    heading = heading or CreateEmptyHeading()
    if level == 1 then
        table.insert(tree, heading)
        return heading
    else
        if #tree == 0 then
            table.insert(tree, CreateEmptyHeading())
        end
        return AddHeading(tree[#tree].children, level-1, heading)
    end
end

function Processor:leaveNode( node )
    local level = cmark.node_get_heading_level(node)
    local heading = AddHeading(self.headingTree, level)
    heading.name = Markdown.renderChildren(node)
    heading.fragmentId = self:_makeUniqueFragmentId(heading.name)
    CreateFragmentNode(node, heading.fragmentId)
    table.insert(self.headingList, heading)
end

local function CreateProcessor()
    local self = { headingTree = {},
                   headingList = {},
                   _usedFragmentIds = {} }
    return setmetatable(self, Processor)
end

return { createProcessor = CreateProcessor }
