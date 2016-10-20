#!/usr/bin/env lua5.2
local stpAvailable, STP = pcall(require, 'StackTracePlus')
if stpAvailable then
    debug.traceback = STP.stacktrace
end

local originalPrint = print
local wx = require 'wx'

-- Remove wx from global namespace:
_G.wx = nil
_G.print = originalPrint -- because wxLua overrides it

-- Early configuration:
local app = wx.wxGetApp()
app:SetAppName('konstrukt-pkman')
app:SetClassName('konstrukt-pkman')
--app:SetExitOnFrameDelete(true)

-- Load modules:
local PackageManager = require 'packagemanager/init'
local ArtProvider = require 'packagemanager-gui/ArtProvider'
local xrc = require 'packagemanager-gui/xrc'
local utils = require 'packagemanager-gui/utils'
local MainFrameView = require 'packagemanager-gui/MainFrameView'
local ChangeListPresenter = require 'packagemanager-gui/ChangeListPresenter'
local SearchPresenter = require 'packagemanager-gui/SearchPresenter'

-- Prepare art provider:
wx.wxArtProvider.Push(ArtProvider)

xrc.initialize()

local mainFrameView = MainFrameView()
PackageManager.initialize()
utils.connect(mainFrameView.frame, 'close_window', function( event )
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
