local here = require 'packagemanager-gui/here'
local wx = require 'wx'
local xmlRes = wx.wxXmlResource.Get()


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

local CastTargetClasses =
{
    wxGauge95 = 'wxGauge'
}

function Xrc.getWindow( root, name )
    assert(root.FindWindow, 'Invalid root object. It must be a subclass of wxWindow.')
    local result = root:FindWindow(name)
    assert(result, 'Can\'t find '..name)
    local targetClassName = result:GetClassInfo():GetClassName()
    targetClassName = CastTargetClasses[targetClassName] or
                      targetClassName
    return result:DynamicCast(targetClassName)
end


return Xrc
