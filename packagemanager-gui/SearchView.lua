local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local Event = require 'packagemanager-gui/Event'
local xrc   = require 'packagemanager-gui/xrc'
local List  = require 'packagemanager-gui/List'


local SearchView = {}
SearchView.__index = SearchView

function SearchView:getQuery()
    return self.searchCtrl:GetValue()
end

function SearchView:setQuery( query )
    self.searchCtrl:ChangeValue(query)
end

function SearchView:freeze()
    self.rootWindow:Freeze()
end

function SearchView:thaw()
    self.rootWindow:Thaw()
end

function SearchView:destroy()
end

return function( rootWindow )
    local self = setmetatable({}, SearchView)

    self.searchChangeEvent = Event()
    self.searchEditEvent   = Event()

    self.rootWindow = rootWindow

    local searchCtrl = xrc.getWindow(self.rootWindow, 'searchCtrl')
    self.searchCtrl = searchCtrl
    utils.connect(searchCtrl, 'command_text_updated', self.searchChangeEvent)

    local resultList = List(xrc.getWindow(self.rootWindow, 'searchResultList'),
                            {{},
                             { label = 'Name' },
                             { label = 'Version' }},
                            {'package-available',
                             'package-installed-updated',
                             'package-install',
                             'package-remove'})
    self.resultList = resultList

    return self
end
