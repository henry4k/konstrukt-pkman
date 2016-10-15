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

--[[
Windows:
    wxART_ERROR
    wxART_QUESTION
    wxART_WARNING
    wxART_INFORMATION
    wxART_HELP
    wxART_FOLDER
    wxART_FOLDER_OPEN
    wxART_DELETE
    wxART_FIND
    wxART_HARDDISK
    wxART_FLOPPY
    wxART_CDROM
    wxART_REMOVABLE

Mac OSX:
    wxART_ERROR
    wxART_INFORMATION
    wxART_WARNING
    wxART_QUESTION
    wxART_FOLDER
    wxART_FOLDER_OPEN
    wxART_NORMAL_FILE
    wxART_EXECUTABLE_FILE
    wxART_CDROM
    wxART_FLOPPY
    wxART_HARDDISK
    wxART_REMOVABLE
    wxART_PRINT
    wxART_DELETE
    wxART_GO_BACK
    wxART_GO_FORWARD
    wxART_GO_HOME
    wxART_HELP_SETTINGS
    wxART_HELP_PAGE
    wxART_HELP_FOLDER
]]

local IconStacks =
{
    ['changes'] =
        IconStack{Unix    = {{type = 'system', name = 'view-refresh'}},
                  Windows = {{type = 'bitmap', file = 'changes?.png'}},
                  Mac     = {{type = 'bitmap', file = 'changes?.png'}}},
    ['scenario'] =
        IconStack{Unix    = {{type = 'system', name = 'bookmarks-organize'},
                             {type = 'system', name = 'bookmarks'},
                             {type = 'system', name = 'user-bookmarks'}},
                  Windows = {{type = 'bitmap', file = 'bookmark?.png'}},
                  Mac     = {{type = 'bitmap', file = 'bookmark?.png'}}},
    ['settings'] =
        IconStack{Unix    = {{type = 'system', name = 'configure'},
                             {type = 'system', name = 'gtk-properties'}},
                  Windows = {{type = 'bitmap', file = 'settings?.png'}},
                  Mac     = {{type = 'bitmap', file = 'settings?.png'}}},
    ['repository'] =
        IconStack{Unix    = {{type = 'system', name = 'server-database'}},
                  Windows = {{type = 'bitmap', file = 'repository?.png'}},
                  Mac     = {{type = 'bitmap', file = 'repository?.png'}}},
    ['package-search'] =
        IconStack{Unix    = {{type = 'system', name = 'system-search'},
                             {type = 'system', name = 'wxART_FIND'}},
                  Windows = {{type = 'bitmap', file = 'search?.png'}},
                  Mac     = {{type = 'bitmap', file = 'search?.png'}}},

    ['package-available'] =
        IconStack{Unix    = {{type = 'bitmap', file = 'empty?.png'}},
                  Windows = {{type = 'bitmap', file = 'empty?.png'}},
                  Mac     = {{type = 'bitmap', file = 'empty?.png'}}},
    ['package-installed-updated'] =
        IconStack{Unix    = {{type = 'system', name = 'document-save'}},
                  Windows = {{type = 'bitmap', file = 'error.png'}},
                  Mac     = {{type = 'bitmap', file = 'error.png'}}},
    ['package-install'] =
        IconStack{Unix    = {{type = 'system', name = 'list-add'}},
                  Windows = {{type = 'bitmap', file = 'add?.png'}},
                  Mac     = {{type = 'bitmap', file = 'add?.png'}}},
    ['package-remove'] =
        IconStack{Unix    = {{type = 'system', name = 'list-remove'}},
                  Windows = {{type = 'bitmap', file = 'remove?.png'}},
                  Mac     = {{type = 'bitmap', file = 'remove?.png'}}},

    ['sort-ascending'] =
        IconStack{Unix    = {{type = 'system', name = 'view-sort-ascending'}},
                  Windows = {{type = 'bitmap', file = 'sort-ascending?.png'}},
                  Mac     = {{type = 'bitmap', file = 'sort-ascending?.png'}}},
    ['sort-descending'] =
        IconStack{Unix    = {{type = 'system', name = 'view-sort-descending'}},
                  Windows = {{type = 'bitmap', file = 'sort-descending?.png'}},
                  Mac     = {{type = 'bitmap', file = 'sort-descending?.png'}}},

    ['edit'] =
        IconStack{Unix    = {{type = 'system', name = 'gtk-edit'}},
                  Windows = {{type = 'bitmap', file = 'edit?.png'}},
                  Mac     = {{type = 'bitmap', file = 'edit?.png'}}},
    ['wxART_UNDO'] =
        IconStack{Unix    = {{type = 'system', name = 'wxART_UNDO'}},
                  Windows = {{type = 'bitmap', file = 'undo?.png'}},
                  Mac     = {{type = 'bitmap', file = 'undo?.png'}}},
    ['wxART_FILE_SAVE'] =
        IconStack{Unix    = {{type = 'system', name = 'wxART_FILE_SAVE'}},
                  Windows = {{type = 'system', name = 'wxART_FLOPPY'}},
                  Mac     = {{type = 'system', name = 'wxART_FLOPPY'}}},
    ['wxART_FILE_OPEN'] =
        IconStack{Unix    = {{type = 'system', name = 'wxART_FILE_OPEN'}},
                  Windows = {{type = 'system', name = 'wxART_FILE_OPEN'}},
                  Mac     = {{type = 'system', name = 'wxART_FILE_OPEN'}}},
    ['wxART_INFORMATION'] =
        IconStack{Unix    = {{type = 'system', name = 'wxART_INFORMATION'}},
                  Windows = {{type = 'system', name = 'wxART_INFORMATION'}},
                  Mac     = {{type = 'system', name = 'wxART_INFORMATION'}}},
    ['wxART_NEW'] =
        IconStack{Unix    = {{type = 'system', name = 'list-add'},
                             {type = 'system', name = 'wxART_NEW'}},
                  Windows = {{type = 'bitmap', file = 'add?.png'}},
                  Mac     = {{type = 'bitmap', file = 'add?.png'}}},
    ['wxART_DELETE'] =
        IconStack{Unix    = {{type = 'system', name = 'list-remove'},
                             {type = 'system', name = 'wxART_DELETE'}},
                  Windows = {{type = 'bitmap', file = 'remove?.png'}},
                  Mac     = {{type = 'system', name = 'wxART_DELETE'}}},
    ['wxART_FIND'] =
        IconStack{Unix    = {{type = 'system', name = 'wxART_FIND'}},
                  Windows = {{type = 'system', name = 'wxART_FIND'}},
                  Mac     = {{type = 'bitmap', file = 'search?.png'}}},
    ['wxART_ERROR'] =
        IconStack{Unix    = {{type = 'system', name = 'wxART_ERROR'}},
                  Windows = {{type = 'system', name = 'wxART_ERROR'}},
                  Mac     = {{type = 'system', name = 'wxART_ERROR'}}},
    ['wxART_WARNING'] =
        IconStack{Unix    = {{type = 'system', name = 'wxART_WARNING'}},
                  Windows = {{type = 'system', name = 'wxART_WARNING'}},
                  Mac     = {{type = 'system', name = 'wxART_WARNING'}}}
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
                local size = wx.wxArtProvider.GetSizeHint(client, true)
                local baseName = iconSource.file:gsub('%?', size:GetWidth())
                local fileName = here(fs.path('icons', baseName))
                result = wx.wxBitmap(fileName)
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
