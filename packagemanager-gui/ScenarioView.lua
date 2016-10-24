local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local Event = require 'packagemanager-gui/Event'
local xrc   = require 'packagemanager-gui/xrc'
local List  = require 'packagemanager-gui/List'


local ScenarioView = {}
ScenarioView.__index = ScenarioView

function ScenarioView:getQuery()
    return self.searchCtrl:GetValue()
end

function ScenarioView:setQuery( query )
    self.searchCtrl:ChangeValue(query)
end

function ScenarioView:clearResults()
end

function ScenarioView:freeze()
    self.rootWindow:Freeze()
end

function ScenarioView:thaw()
    self.rootWindow:Thaw()
end

function ScenarioView:destroy()
end

function ScenarioView:setScenarioTree( tree )
end

return function( rootWindow )
    local self = setmetatable({}, ScenarioView)

    self.searchChangeEvent   = Event()
    self.createScenarioEvent = Event()
    self.columnClickEvent    = Event()

    self.rootWindow = rootWindow

    -- Make sure, that the sidebar has at least N pixels:
    local sidebarWidth = 250
    local splitter = xrc.getWindow(rootWindow, 'splitter')
    splitter:SetSashPosition(splitter:GetSize():GetWidth()-sidebarWidth)

    local searchCtrl = xrc.getWindow(rootWindow, 'searchCtrl')
    self.searchCtrl = searchCtrl
    utils.connect(searchCtrl, 'command_text_updated', self.searchChangeEvent)

    local createScenarioButton = xrc.getWindow(rootWindow, 'createScenarioButton')
    utils.connect(createScenarioButton, 'command_button_clicked', self.createScenarioEvent)

    local comp = function(a,b) return a < b end
    local searchResultList = List(xrc.getWindow(rootWindow, 'searchResultList'),
                                  {{label='name'}, {label='date'}},
                                  {})
    searchResultList:freeze()
    searchResultList:addRow{{text='bbb', value=2}, {text='222', value=20}}
    searchResultList:addRow{{text='aaa', value=1}, {text='111', value=10}}
    searchResultList:addRow{{text='ccc', value=3}, {text='333', value=30}}
    searchResultList:adaptColumnWidths()
    searchResultList:thaw()

    return self
end
