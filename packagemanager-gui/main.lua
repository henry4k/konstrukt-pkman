#!/usr/bin/env lua5.2
local wx = require 'wx'

-- Remove wx from global namespace:
_G.wx = nil

-- Early configuration:
local app = wx.wxGetApp()
app:SetAppName('konstrukt-pkman')
app:SetClassName('konstrukt-pkman')

-- Load modules:
local PackageManager = require 'packagemanager/init'
local ArtProvider = require 'packagemanager-gui/artprovider'
local Xrc = require 'packagemanager-gui/xrc'
local MainFrameView = require 'packagemanager-gui/mainframeview'
local ChangeListController = require 'packagemanager-gui/changelistcontroller'
local RequirementGroupsController = require 'packagemanager-gui/requirementgroupscontroller'
local SearchController = require 'packagemanager-gui/searchcontroller'

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

local mainFrameView = MainFrameView()
PackageManager.initialize()
mainFrameView.frame:Connect(wx.wxEVT_CLOSE_WINDOW, PackageManager.finalize)

local statusBarView = mainFrameView.statusBarView
local changeListView = mainFrameView.changeListView
local changeListController = ChangeListController(changeListView)
local requirementGroupsView = mainFrameView.requirementGroupsView
local requirementGroupsController = RequirementGroupsController(requirementGroupsView)
local searchView = mainFrameView.searchView
local searchController = SearchController(searchView)

mainFrameView:show()

-- Main loop:
print('BEGIN MAIN LOOP')
app:MainLoop()
print('END MAIN LOOP')
