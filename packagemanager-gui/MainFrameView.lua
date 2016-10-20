local xrc            = require 'packagemanager-gui/xrc'
local ChangeListView = require 'packagemanager-gui/ChangeListView'
local SearchView     = require 'packagemanager-gui/SearchView'
local StatusBarView  = require 'packagemanager-gui/StatusBarView'


local MainFrameView = {}
MainFrameView.__index = MainFrameView

function MainFrameView:show()
    self.frame:Show()
end

function MainFrameView:destroy()
    self.changeListView:destroy()
    self.searchView:destroy()
    self.statusBarView:destroy()
    self.frame:Destroy()
end

return function()
    local self = setmetatable({}, MainFrameView)

    local frame = xrc.createFrame('mainFrame')
    --frame:SetAcceleratorTable(...)
    --frame:SetDropTarget(...)
    self.frame = frame

    local changeRoot = xrc.getWindow(frame, 'changesPanel')
    self.changeListView = ChangeListView(changeRoot)

    local searchRoot = xrc.getWindow(frame, 'searchPanel')
    self.searchView = SearchView(searchRoot)

    local statusBar = xrc.getWindow(frame, 'statusBar')
    self.statusBarView = StatusBarView(statusBar)

    return self
end
