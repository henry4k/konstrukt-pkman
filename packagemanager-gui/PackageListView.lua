local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local xrc   = require 'packagemanager-gui/xrc'
local Event = require 'packagemanager-gui/Event'
local List  = require 'packagemanager-gui/List'


local PackageListView = {}
PackageListView.__index = PackageListView

function PackageListView:getQuery()
    return self.searchCtrl:GetValue()
end

function PackageListView:setQuery( query )
    self.searchCtrl:ChangeValue(query)
end

function PackageListView:getName()
    return self.nameText:GetValue()
end

function PackageListView:setName( name )
    self.nameText:ChangeValue(name)
end

function PackageListView:getDescription()
    return self.descriptionText:GetValue()
end

function PackageListView:setDescription( desc )
    self.descriptionText:ChangeValue(desc)
end

function PackageListView:enableDeleteButton( enabled )
    self.deleteButton:Enable(enabled)
end

function PackageListView:enableReloadButton( enabled )
    self.reloadButton:Enable(enabled)
end

function PackageListView:enableSaveButton( enabled )
    self.saveButton:Enable(enabled)
end

function PackageListView:enableLaunchButton( enabled )
    self.launchButton:Enable(enabled)
end

function PackageListView:enableDetailsPanel( enabled )
    self.detailsPanel:Enable(enabled)
end

function PackageListView:freeze()
    self.rootWindow:Freeze()
end

function PackageListView:thaw()
    self.rootWindow:Thaw()
end

function PackageListView:destroy()
end

return function( rootWindow )
    local self = setmetatable({}, PackageListView)

    self.searchChangeEvent = Event()
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

    local searchCtrl = xrc.getWindow(self.rootWindow, 'searchCtrl')
    self.searchCtrl = searchCtrl
    utils.connect(searchCtrl, 'command_text_updated', self.searchChangeEvent)

    local resultList = List(xrc.getWindow(self.rootWindow, 'resultList'),
                            {{},
                             { label = 'Name' },
                             { label = 'Version' },
                             { label = 'Date' }},
                            {'package-available',
                             'package-installed-updated',
                             'package-install',
                             'package-remove'})
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
