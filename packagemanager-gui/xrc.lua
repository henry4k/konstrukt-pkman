local wx = require 'wx'
local xmlRes = wx.wxXmlResource.Get()
local utils = require 'packagemanager-gui/utils'
local here  = require 'packagemanager-gui/here'


local xrc = {}

function xrc.initialize()
    xmlRes:InitAllHandlers()
    xmlRes:Load(here('layout.xrc'))
end

function xrc.createFrame( name, parent )
    local frame = wx.wxFrame()
    if xmlRes:LoadFrame(frame, parent or wx.NULL, name) then
        return frame
    else
        frame:Destroy()
        error('Can\'t load '..name)
    end
end

function xrc.getWindow( root, name )
    assert(root.FindWindow, 'Invalid root object. It must be a subclass of wxWindow.')
    local result = root:FindWindow(name)
    assert(result, 'Can\'t find '..name)
    return utils.autoCast(result)
end


return xrc
