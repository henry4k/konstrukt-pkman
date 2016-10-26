local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local xrc   = require 'packagemanager-gui/xrc'
local Event = require 'packagemanager-gui/Event'


local RequirementListView = {}
RequirementListView.__index = RequirementListView

local ResultGridColumns = 3

function RequirementListView:getQuery()
    return self.searchCtrl:GetValue()
end

function RequirementListView:setQuery( query )
    self.searchCtrl:ChangeValue(query)
end

function RequirementListView:freeze()
    self.rootWindow:Freeze()
end

function RequirementListView:thaw()
    utils.updateWindow(self.rootWindow)
    self.rootWindow:Thaw()
end

function RequirementListView:destroy()
end

function RequirementListView:clear()
    local resultGrid = self.resultGrid
    for requirement in pairs(self.requirementEntries) do
        self:removeRequirement(requirement)
    end
end

function RequirementListView:addRequirement( requirement )
    local resultGrid = self.resultGrid
    local resultWindow = self.resultWindow

    local entry = {}

    local insertIndex = resultGrid:GetChildren():GetCount() - ResultGridColumns

    local packageNameCtrl = wx.wxTextCtrl( resultWindow, wx.wxID_ANY, requirement.packageName, wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    resultGrid:Insert(insertIndex, packageNameCtrl, 0, wx.wxALL + wx.wxEXPAND, 5 )
    insertIndex = insertIndex + 1

    local versionRangeCtrl = wx.wxTextCtrl( resultWindow, wx.wxID_ANY, tostring(requirement.versionRange), wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    resultGrid:Insert(insertIndex, versionRangeCtrl, 0, wx.wxALL + wx.wxEXPAND, 5 )
    insertIndex = insertIndex + 1

    local function changeFn()
        self.changeRequirementEvent(requirement,
                                    packageNameCtrl:GetValue(),
                                    versionRangeCtrl:GetValue())
    end
    utils.connect(packageNameCtrl,  'command_text_updated', changeFn)
    utils.connect(versionRangeCtrl, 'command_text_updated', changeFn)

    local removeButton = wx.wxBitmapButton( resultWindow, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_DELETE, wx.wxART_BUTTON ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    resultGrid:Insert(insertIndex, removeButton, 0, wx.wxALL, 5 )
    insertIndex = insertIndex + 1

    utils.connect(removeButton, 'command_button_clicked', function()
        self.removeRequirementEvent(requirement)
    end)

    entry.windows = { packageNameCtrl = packageNameCtrl,
                      versionRangeCtrl = versionRangeCtrl,
                      removeButton = removeButton }
    self.requirementEntries[requirement] = entry
end

function RequirementListView:showRequirement( requirement )
    -- TODO Its a lie. It just scrolls to the bottom at the moment.
    utils.updateWindow(self.resultWindow)
    utils.scrollWindowToEnd(self.resultWindow)
end

function RequirementListView:removeRequirement( requirement )
    local entry = assert(self.requirementEntries[requirement])
    local resultGrid = self.resultGrid
    for _, window in pairs(entry.windows) do
        resultGrid:Detach(window)
        window:Destroy()
    end
    self.requirementEntries[requirement] = nil
    utils.updateWindow(self.resultWindow)
end

local function GetHintColour( mode )
    local colour = wx.wxSystemSettings.GetColour(wx.wxSYS_COLOUR_WINDOW)
    if mode ~= 'none' then
        local referenceColour = wx.wxSystemSettings.GetColour(wx.wxSYS_COLOUR_WINDOWFRAME)
        if mode == 'warning' then
            colour:Set(colour:Red(), colour:Green(), referenceColour:Blue())
        elseif mode == 'error' then
            colour:Set(colour:Red(), referenceColour:Green(), referenceColour:Blue())
        else
            error('Unknown mode.')
        end
    end
    return colour
end

---
-- @param[type=string] mode
-- One of these: `none`, `warning`, `error`
--
-- @param[type=string,opt] message
--
function RequirementListView:setVersionRangeHint( requirement, mode, message )
    local entry = assert(self.requirementEntries[requirement])
    local ctrl = entry.windows.versionRangeCtrl
    ctrl:SetBackgroundColour(GetHintColour(mode))
    ctrl:SetToolTip(message or '')
end

return function( rootWindow )
    local self = setmetatable({}, RequirementListView)

    self.requirementEntries = {}

    self.searchChangeEvent = Event()
    self.addRequirementEvent = Event()
    self.removeRequirementEvent = Event()
    self.changeRequirementEvent = Event()

    self.rootWindow = rootWindow

    local searchCtrl = xrc.getWindow(rootWindow, 'searchCtrl')
    self.searchCtrl = searchCtrl
    utils.connect(searchCtrl, 'command_text_updated', self.searchChangeEvent)

    local resultWindow = xrc.getWindow(rootWindow, 'resultWindow')
    self.resultWindow = resultWindow

    self.resultGrid = resultWindow:GetSizer()

    local addRequirementButton = xrc.getWindow(rootWindow, 'addRequirementButton')
    utils.connect(addRequirementButton, 'command_button_clicked', self.addRequirementEvent)

    return self
end
