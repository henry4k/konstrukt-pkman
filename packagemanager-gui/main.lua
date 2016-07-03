#!/usr/bin/env lua5.2
local wx = require 'wx'
local MainFrame = require 'packagemanager-gui/mainframe'
local ArtProvider = require 'packagemanager-gui/artprovider'
local Xrc = require 'packagemanager-gui/xrc'

-- Prepare art provider:
wx.wxArtProvider.Push(ArtProvider)

Xrc.initialize()

local mainFrame = MainFrame()
mainFrame:addChangeEntry()
mainFrame:addChangeEntry()
mainFrame:addChangeEntry()
mainFrame:removeChangeEntry(1)
mainFrame:addRequirementGroupEntry('wurst', {{},{},{}})
mainFrame:addRequirementGroupEntry('kaese', {{},{},{}})
mainFrame:addRequirementGroupEntry('nifty', {{},{},{}})
mainFrame:removeRequirementGroupEntry(2)
mainFrame.frame:Show()

wx.wxGetApp():MainLoop()
