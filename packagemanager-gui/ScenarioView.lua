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

function ScenarioView:getName()
    return self.nameText:GetValue()
end

function ScenarioView:setName( name )
    self.nameText:ChangeValue(name)
end

function ScenarioView:getDescription()
    return self.descriptionText:GetValue()
end

function ScenarioView:setDescription( desc )
    self.descriptionText:ChangeValue(desc)
end

function ScenarioView:enableDeleteButton( enabled )
    self.deleteButton:Enable(enabled)
end

function ScenarioView:enableReloadButton( enabled )
    self.reloadButton:Enable(enabled)
end

function ScenarioView:enableSaveButton( enabled )
    self.saveButton:Enable(enabled)
end

function ScenarioView:enableLaunchButton( enabled )
    self.launchButton:Enable(enabled)
end

function ScenarioView:enableDetailsPanel( enabled )
    self.detailsPanel:Enable(enabled)
end

function ScenarioView:freeze()
    self.rootWindow:Freeze()
end

function ScenarioView:thaw()
    self.rootWindow:Thaw()
end

function ScenarioView:destroy()
end

return function( rootWindow )
    local self = setmetatable({}, ScenarioView)

    self.searchChangeEvent   = Event()
    self.createScenarioEvent = Event()
    self.nameChangeEvent     = Event()
    self.descriptionChangeEvent = Event()
    self.deleteEvent         = Event()
    self.reloadEvent         = Event()
    self.saveEvent           = Event()
    self.launchEvent         = Event()

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

    local resultList = List(xrc.getWindow(rootWindow, 'resultList'),
                            {{},
                             { label = 'Name' },
                             { label = 'Date' }},
                            {})
    self.resultList = resultList

    local nameText = xrc.getWindow(rootWindow, 'nameText')
    self.nameText = nameText
    utils.connect(nameText, 'command_text_updated', self.nameChangeEvent)

    local descriptionText = xrc.getWindow(rootWindow, 'descriptionText')
    self.descriptionText = descriptionText
    utils.connect(descriptionText, 'command_text_updated', self.descriptionChangeEvent)

    local deleteButton = xrc.getWindow(rootWindow, 'deleteButton')
    self.deleteButton = deleteButton
    utils.connect(deleteButton, 'command_button_clicked', self.deleteEvent)

    local reloadButton = xrc.getWindow(rootWindow, 'reloadButton')
    self.reloadButton = reloadButton
    utils.connect(reloadButton, 'command_button_clicked', self.reloadEvent)

    local saveButton = xrc.getWindow(rootWindow, 'saveButton')
    self.saveButton = saveButton
    utils.connect(saveButton, 'command_button_clicked', self.saveEvent)

    local launchButton = xrc.getWindow(rootWindow, 'launchButton')
    self.launchButton = launchButton
    utils.connect(launchButton, 'command_button_clicked', self.launchEvent)

    self.detailsPanel = xrc.getWindow(rootWindow, 'detailsPanel')

    return self
end
