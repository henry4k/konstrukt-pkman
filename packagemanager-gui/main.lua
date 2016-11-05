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

-- Load modules:
local PackageManager = require 'packagemanager/init'
local ArtProvider = require 'packagemanager-gui/ArtProvider'
local xrc = require 'packagemanager-gui/xrc'
local utils = require 'packagemanager-gui/utils'
local Event = require 'packagemanager-gui/Event'
local MainFrameView = require 'packagemanager-gui/MainFrameView'
local ChangeListPresenter = require 'packagemanager-gui/ChangeListPresenter'
local PackageListPresenter = require 'packagemanager-gui/PackageListPresenter'
local RequirementListPresenter = require 'packagemanager-gui/RequirementListPresenter'

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

local timer = wx.wxTimer(mainFrameView.frame)
local timerEvent = Event()
timerEvent:addListener(PackageManager.update)
utils.connect(mainFrameView.frame, 'timer', timerEvent)

local statusBarView = mainFrameView.statusBarView

local requirementListView = mainFrameView.requirementListView
local requirementListPresenter = RequirementListPresenter(requirementListView)

local changeListView = mainFrameView.changeListView
local changeListPresenter = ChangeListPresenter(changeListView, requirementListPresenter, mainFrameView, timerEvent)

local packageListView = mainFrameView.packageListView
local packageListPresenter = PackageListPresenter(packageListView)

mainFrameView:show()
timer:Start(1000)

-- Main loop:
app:MainLoop()
