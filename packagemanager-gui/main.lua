#!/usr/bin/env lua5.2
local wx = require 'wx'
local ArtProvider = require 'packagemanager-gui/artprovider'
local Xrc = require 'packagemanager-gui/xrc'
local MainFrameView = require 'packagemanager-gui/mainframeview'
local ChangeListController = require 'packagemanager-gui/changelistcontroller'
local RequirementGroupsController = require 'packagemanager-gui/requirementgroupscontroller'

-- Remove wx from global namespace:
_G.wx = nil

-- Prepare art provider:
wx.wxArtProvider.Push(ArtProvider)

-- Redefine print as it somehow stops working after the GUI has launched
print = function( ... )
    for i, v in ipairs({...}) do
        if i > 1 then
            io.stdout:write('\t')
        end
        io.stdout:write(tostring(v))
    end
    io.stdout:write('\n')
    io.stdout:flush()
end

Xrc.initialize()

-- Tests:
local mainFrameView = MainFrameView()

local changeListView = mainFrameView.changeListView
local changeListController = ChangeListController(changeListView)
local requirementGroupsView = mainFrameView.requirementGroupsView
local requirementGroupsController = RequirementGroupsController(requirementGroupsView)

changeListView:addInstallChange('base-game', '0.1.0')
changeListView:addInstallChange('base-game', '0.1.0')
local change = changeListView:addInstallChange('base-game', '0.1.0')
changeListView:removeChange(change)

requirementGroupsView:addGroup('wurst')
requirementGroupsView:addGroup('kaese')
local group = requirementGroupsView:addGroup('nifty')
requirementGroupsView:removeGroup(group)

mainFrameView:show()

-- Main loop:
print('BEGIN MAIN LOOP')
wx.wxGetApp():MainLoop()
print('END MAIN LOOP')
