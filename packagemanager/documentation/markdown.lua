local cmark = require 'cmark'


local CMarkOptions = cmark.OPT_DEFAULT

local function TrimWhitespace( str )
    return string.match(str, '^%s*(.-)%s*$')
end

local function RenderChildren( parent )
    local root = cmark.node_new(cmark.NODE_CUSTOM_BLOCK)
    cmark.node_set_on_enter(root, '')
    cmark.node_set_on_exit(root, '')

    -- Gather child nodes:
    local children = {}
    do
        local child = cmark.node_first_child(parent)
        while(child) do
            table.insert(children, child)
            child = cmark.node_next(child)
        end
    end

    -- Move all child nodes to a temporary container:
    for _, child in ipairs(children) do
        cmark.node_unlink(child) -- from original container
        cmark.node_append_child(root, child)
    end

    local html = TrimWhitespace(cmark.render_html(root, CMarkOptions))

    -- Move the child nodes back to the original container:
    for _, child in ipairs(children) do
        cmark.node_unlink(child) -- from temporary container
        cmark.node_append_child(parent, child)
    end

    cmark.node_free(root)
    return html
end

local function Parse( markdownSource )
    return assert(cmark.parse_document(markdownSource,
                                       #markdownSource,
                                       CMarkOptions))
end

local function Render( rootNode )
    return assert(cmark.render_html(rootNode, CMarkOptions))
end

local function NodeMatchesFilter( nodeType, filter )
    for _, allowedNodeType in ipairs(filter) do
        if allowedNodeType == nodeType then
            return true
        end
    end
end

local function noop() end

---
-- @param processors
-- A list of processors.  processors have these properties:
--
-- - `nodeFilter`:
--   Defines which nodes the processor is interested in.
--   At the moment this must be a node type name.
-- - `enterNode( processor, node )`: (optional)
--   This callback may not be used for modifications.
--   Also keep in mind that leaf nodes generate no enter events.
-- - `leaveNode( processor, node )`: (optional)
--   This callback may be used for modifications.
--
local function Process( rootNode, processors )
    for node, entering, nodeType in cmark.walk(rootNode) do
        for _, processor in ipairs(processors) do
            if NodeMatchesFilter(nodeType, processor.nodeFilter) then
                local eventFn
                if entering then
                    eventFn = processor.enterNode or noop
                else
                    eventFn = processor.leaveNode or noop
                end
                eventFn(processor, node)
            end
        end
    end
end

return { parse = Parse,
         render = Render,
         renderChildren = RenderChildren,
         process = Process }
