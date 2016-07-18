local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local Event = require 'packagemanager-gui/event'
local Xrc   = require 'packagemanager-gui/xrc'


local SearchView = {}
SearchView.__index = SearchView

function SearchView:freeze()
    self.rootWindow:Freeze()
end

function SearchView:thaw()
    self.rootWindow:Thaw()
end

function SearchView:destroy()
    --  TODO
end

return function( rootWindow )
    local self = setmetatable({}, SearchView)

    self.rootWindow = rootWindow

    local searchCtrl = Xrc.getWindow(self.rootWindow, 'searchCtrl')
    local searchEditButton = Xrc.getWindow(self.rootWindow, 'searchEditButton')
    local searchResultList = Xrc.getWindow(self.rootWindow, 'searchResultList')


    return self
end
