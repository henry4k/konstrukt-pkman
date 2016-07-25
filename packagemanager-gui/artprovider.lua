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
        print('No icon stack defined for '..os)
    end
    return stack
end

local IconStacks =
{
    ['changes'] =
        IconStack{Unix    = {{type = 'system', name = 'view-refresh'}},
                  Windows = {{type = 'bitmap', file = 'error.png'}},
                  Mac     = {{type = 'bitmap', file = 'error.png'}}},
    ['requirements'] =
        IconStack{Unix    = {{type = 'system', name = 'bookmarks-organize'},
                             {type = 'system', name = 'bookmarks'},
                             {type = 'system', name = 'user-bookmarks'}},
                  Windows = {{type = 'bitmap', file = 'error.png'}},
                  Mac     = {{type = 'bitmap', file = 'error.png'}}},
    ['settings'] =
        IconStack{Unix    = {{type = 'system', name = 'configure'},
                             {type = 'system', name = 'gtk-properties'}},
                  Windows = {{type = 'bitmap', file = 'error.png'}},
                  Mac     = {{type = 'bitmap', file = 'error.png'}}},
    ['package-search'] =
        IconStack{Unix    = {{type = 'system', name = 'system-search'},
                             {type = 'system', name = 'wxART_FIND'}},
                  Windows = {{type = 'bitmap', file = 'error.png'}},
                  Mac     = {{type = 'bitmap', file = 'error.png'}}},

    ['package-available'] =
        IconStack{Unix    = {{type = 'bitmap', file = 'empty.png'}},
                  Windows = {{type = 'bitmap', file = 'error.png'}},
                  Mac     = {{type = 'bitmap', file = 'error.png'}}},
    ['package-installed-updated'] =
        IconStack{Unix    = {{type = 'system', name = 'document-save'}},
                  Windows = {{type = 'bitmap', file = 'error.png'}},
                  Mac     = {{type = 'bitmap', file = 'error.png'}}},
    ['package-install'] =
        IconStack{Unix    = {{type = 'system', name = 'list-add'}},
                  Windows = {{type = 'bitmap', file = 'error.png'}},
                  Mac     = {{type = 'bitmap', file = 'error.png'}}},
    ['package-remove'] =
        IconStack{Unix    = {{type = 'system', name = 'list-remove'}},
                  Windows = {{type = 'bitmap', file = 'error.png'}},
                  Mac     = {{type = 'bitmap', file = 'error.png'}}},

    ['edit'] =
        IconStack{Unix    = {{type = 'system', name = 'gtk-edit'}},
                  Windows = {{type = 'bitmap', file = 'error.png'}},
                  Mac     = {{type = 'bitmap', file = 'error.png'}}},
    ['wxART_INFORMATION'] =
        IconStack{Unix    = {{type = 'system', name = 'wxART_INFORMATION'}},
                  Windows = {{type = 'system', name = 'wxART_INFORMATION'}},
                  Mac     = {{type = 'system', name = 'wxART_INFORMATION'}}},
    ['wxART_NEW'] =
        IconStack{Unix    = {{type = 'system', name = 'list-add'},
                             {type = 'system', name = 'wxART_NEW'}},
                  Windows = {{type = 'bitmap', file = 'error.png'}},
                  Mac     = {{type = 'bitmap', file = 'error.png'}}},
    ['wxART_DELETE'] =
        IconStack{Unix    = {{type = 'system', name = 'list-remove'},
                             {type = 'system', name = 'wxART_DELETE'}},
                  Windows = {{type = 'bitmap', file = 'error.png'}},
                  Mac     = {{type = 'system', name = 'wxART_DELETE'}}},
    ['wxART_FIND'] =
        IconStack{Unix    = {{type = 'system', name = 'wxART_FIND'}},
                  Windows = {{type = 'system', name = 'wxART_FIND'}},
                  Mac     = {{type = 'bitmap', file = 'error.png'}}}
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
