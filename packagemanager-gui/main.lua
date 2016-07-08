#!/usr/bin/env lua5.2
local wx = require 'wx'
local ArtProvider = require 'packagemanager-gui/artprovider'
local Xrc = require 'packagemanager-gui/xrc'
local MainFrameView = require 'packagemanager-gui/mainframeview'

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
mainFrameView:show()

local changeListView = mainFrameView.changeListView
changeListView:addInstallEntry('base-game', '0.1.0')
changeListView:addInstallEntry('base-game', '0.1.0')
changeListView:addInstallEntry('base-game', '0.1.0')
changeListView:removeEntry(1)

changeListView.applyButtonPressed:addListener(function()
    changeListView:enableApplyButton(false)
    changeListView:enableAbortButton(true)
end)

changeListView.abortButtonPressed:addListener(function()
    changeListView:enableAbortButton(false)
    changeListView:enableApplyButton(true)
end)

local requirementGroupsView = mainFrameView.requirementGroupsView
requirementGroupsView:addGroupEntry('wurst')
requirementGroupsView:addGroupEntry('kaese')
requirementGroupsView:addGroupEntry('nifty')
requirementGroupsView:removeGroupEntry('nifty')

-- Main loop:
print('BEGIN MAIN LOOP')
wx.wxGetApp():MainLoop()
print('END MAIN LOOP')
