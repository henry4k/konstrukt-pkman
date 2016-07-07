#!/usr/bin/env lua5.2
local wx = require 'wx'
local ArtProvider = require 'packagemanager-gui/artprovider'
local Xrc = require 'packagemanager-gui/xrc'
local MainFrameView = require 'packagemanager-gui/mainframeview'

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
mainFrameView:show()

local changeListView = mainFrameView.changeListView
changeListView:addEntry()
changeListView:addEntry()
changeListView:addEntry()
changeListView:removeEntry(1)

local requirementGroupsView = mainFrameView.requirementGroupsView
requirementGroupsView:addGroupEntry('wurst', {{}, {}, {}, {}, {}})
requirementGroupsView:addGroupEntry('kaese', {{}, {}, {}, {}, {}})
requirementGroupsView:addGroupEntry('nifty', {{}, {}, {}, {}, {}})
requirementGroupsView:removeGroupEntry(2)

print('BEGIN MAIN LOOP')
wx.wxGetApp():MainLoop()
print('END MAIN LOOP')
