local wx = require 'wx'
local xmlRes = wx.wxXmlResource.Get()
local utils = require 'packagemanager-gui/utils'
local here  = require 'packagemanager-gui/here'


local Xrc = {}

function Xrc.initialize()
    xmlRes:InitAllHandlers()
    xmlRes:Load(here('layout.xrc'))
end

function Xrc.createFrame( name )
    local frame = wx.wxFrame()
    if xmlRes:LoadFrame(frame, wx.NULL, name) then
        return frame
    else
        frame:Destroy()
        error('Can\'t load '..name)
    end
end

function Xrc.getWindow( root, name )
    assert(root.FindWindow, 'Invalid root object. It must be a subclass of wxWindow.')
    local result = root:FindWindow(name)
    assert(result, 'Can\'t find '..name)
    return utils.autoCast(result)
end


return Xrc
