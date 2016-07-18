local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local here  = require 'packagemanager-gui/here'
local fs    = require 'packagemanager/fs'


local ArtProvider = wx.wxLuaArtProvider()

local IgnoreCallbacks = false

local function IconStack( osDependantIconStacks )
    local os = utils.getOperatingSystem()
    local stack = osDependantIconStacks[os]
    if not stack then
        stack = FallbackStack
        print('No icon stack defined for '..os)
    end
    return stack
end

local IconStacks =
{
    ['changes'] =
        IconStack{Unix    = {{type = 'system', name = 'view-refresh'}}},
    ['requirements'] =
        IconStack{Unix    = {{type = 'system', name = 'bookmarks-organize'},
                             {type = 'system', name = 'bookmarks'},
                             {type = 'system', name = 'user-bookmarks'}}},
    ['settings'] =
        IconStack{Unix    = {{type = 'system', name = 'configure'},
                             {type = 'system', name = 'gtk-properties'}}},
    ['package-search'] =
        IconStack{Unix    = {{type = 'system', name = 'system-search'},
                             {type = 'system', name = 'wxART_FIND'}}},

    ['package-available'] =
        IconStack{Unix    = {{type = 'bitmap', file = 'empty.png'}}},
    ['package-installed-updated'] =
        IconStack{Unix    = {{type = 'system', name = 'document-save'}}},
    ['package-install'] =
        IconStack{Unix    = {{type = 'system', name = 'list-add'}}},
    ['package-remove'] =
        IconStack{Unix    = {{type = 'system', name = 'list-remove'}}},

    ['edit'] =
        IconStack{Unix    = {{type = 'system', name = 'gtk-edit'}}},
    ['wxART_INFORMATION'] =
        IconStack{Unix    = {{type = 'system', name = 'wxART_INFORMATION'}}},
    ['wxART_NEW'] =
        IconStack{Unix    = {{type = 'system', name = 'list-add'},
                             {type = 'system', name = 'wxART_NEW'}}},
    ['wxART_DELETE'] =
        IconStack{Unix    = {{type = 'system', name = 'list-remove'},
                             {type = 'system', name = 'wxART_DELETE'}}},
    ['wxART_FIND'] =
        IconStack{Unix    = {{type = 'system', name = 'wxART_FIND'}}}
}

function ArtProvider:DoGetSizeHint( client )
    if IgnoreCallbacks then
        return wx.NULL
    end

    print('ArtProvider:DoGetSizeHint', client)
    return self.GetSizeHint(client, true)
end

function ArtProvider:CreateBitmap( id, client, size )
    if IgnoreCallbacks then
        return wx.NULL
    end
    IgnoreCallbacks = true

    local iconStack = IconStacks[id]
    local result
    if iconStack then
        for _, iconSource in ipairs(iconStack) do
            if iconSource.type == 'system' then
                result = wx.wxArtProvider.GetBitmap(iconSource.name, client, size)
            elseif iconSource.type == 'bitmap' then
                result = wx.wxBitmap(here(fs.path('icons', iconSource.file)))
            else
                error(id..': Unknown icon source '..iconSource.type..'.')
            end
            if result:Ok() then
                break
            end
        end
    end

    if not result or not result:Ok() then
        result = wx.wxArtProvider.GetBitmap('wxART_ERROR', client, size)
        if not iconStack then
            print(id..': No item stack found.')
        else
            print(id..': Stack found, but no icon available.')
        end
    end

    IgnoreCallbacks = false
    return result
end


return ArtProvider
