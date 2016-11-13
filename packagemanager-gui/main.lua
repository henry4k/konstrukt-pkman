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
local xrc            = require 'packagemanager-gui/xrc'
local utils          = require 'packagemanager-gui/utils'
local ArtProvider    = require 'packagemanager-gui/ArtProvider'
local MainView       = require 'packagemanager-gui/MainView'
local MainPresenter  = require 'packagemanager-gui/MainPresenter'

-- Prepare art provider:
wx.wxArtProvider.Push(ArtProvider)

xrc.initialize()
PackageManager.initialize()

local mainView = MainView()
local mainPresenter = MainPresenter(mainView)

utils.connect(mainView.frame, 'close_window', function( event )
    mainPresenter:destroy()
    PackageManager.finalize()
    event:Skip()
end)

mainView:show()

-- Main loop:
app:MainLoop()
