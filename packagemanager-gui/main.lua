#!/usr/bin/env lua5.2
local wx = require 'wx'

-- Remove wx from global namespace:
_G.wx = nil

-- Early configuration:
local app = wx.wxGetApp()
app:SetAppName('konstrukt-pkman')
app:SetClassName('konstrukt-pkman')
--app:SetExitOnFrameDelete(true)

-- Load modules:
local PackageManager = require 'packagemanager/init'
local ArtProvider = require 'packagemanager-gui/ArtProvider'
local xrc = require 'packagemanager-gui/xrc'
local MainFrameView = require 'packagemanager-gui/MainFrameView'
local ChangeListPresenter = require 'packagemanager-gui/ChangeListPresenter'
local SearchPresenter = require 'packagemanager-gui/SearchPresenter'

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

xrc.initialize()

local mainFrameView = MainFrameView()
PackageManager.initialize()
mainFrameView.frame:Connect(wx.wxEVT_CLOSE_WINDOW, function( event )
    mainFrameView:destroy()
    PackageManager.finalize()
    -- ensure the event is skipped to allow the frame to close
    event:Skip()
end)

local statusBarView = mainFrameView.statusBarView
local changeListView = mainFrameView.changeListView
local changeListPresenter = ChangeListPresenter(changeListView)
local searchView = mainFrameView.searchView
local searchPresenter = SearchPresenter(searchView)

mainFrameView:show()

-- Main loop:
app:MainLoop()
