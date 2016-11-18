local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local xrc   = require 'packagemanager-gui/xrc'
local Event = require 'packagemanager-gui/Event'


local RepositoryListView = {}
RepositoryListView.__index = RepositoryListView

local ListGridColumns = 2

function RepositoryListView:freeze()
    self.rootWindow:Freeze()
end

function RepositoryListView:thaw()
    utils.updateWindow(self.rootWindow)
    self.rootWindow:Thaw()
end

function RepositoryListView:destroy()
end

function RepositoryListView:addRepository( url )
    local listGrid = self.listGrid
    local listWindow = self.listWindow

    local entry = {}

    local insertIndex = listGrid:GetChildren():GetCount() - ListGridColumns

    local urlCtrl = wx.wxTextCtrl( listWindow, wx.wxID_ANY, url, wx.wxDefaultPosition, wx.wxDefaultSize, 0 )
    listGrid:Insert(insertIndex, urlCtrl, 0, wx.wxALL + wx.wxEXPAND, 5 )
    insertIndex = insertIndex + 1

    utils.connect(urlCtrl, 'command_text_updated', function()
        self.changeRepositoryEvent(entry, urlCtrl:GetValue())
    end)

    local removeButton = wx.wxBitmapButton( listWindow, wx.wxID_ANY, wx.wxArtProvider.GetBitmap( wx.wxART_DELETE, wx.wxART_BUTTON ), wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBU_AUTODRAW )
    listGrid:Insert(insertIndex, removeButton, 0, wx.wxALL, 5 )
    insertIndex = insertIndex + 1

    utils.connect(removeButton, 'command_button_clicked', function()
        self.removeRepositoryEvent(entry, urlCtrl:GetValue())
    end)

    entry.windows = { urlCtrl = urlCtrl,
                      removeButton = removeButton }
    self.repositoryEntries[entry] = true

    return entry
end

function RepositoryListView:showRepository( entry )
    -- TODO Its a lie. It just scrolls to the bottom at the moment.
    utils.updateWindow(self.listWindow)
    utils.scrollWindowToEnd(self.listWindow)
end

function RepositoryListView:removeRepository( entry )
    assert(self.repositoryEntries[entry])
    local listGrid = self.listGrid
    for _, window in pairs(entry.windows) do
        listGrid:Detach(window)
        window:Destroy()
    end
    self.repositoryEntries[entry] = nil
    utils.updateWindow(self.listWindow)
end

function RepositoryListView:getRepositoryUrls()
    local urlSet = {}
    local urls = {}
    for entry in pairs(self.repositoryEntries) do
        local url = entry.windows.urlCtrl:GetValue()
        if not urlSet[url] then
            urlSet[url] = true
            table.insert(urls, url)
        end
    end
    return urls
end

function RepositoryListView:enableApplyButton( enable )
    self.applyButton:Enable(enable)
end

return function( rootWindow )
    local self = setmetatable({}, RepositoryListView)

    self.repositoryEntries = {}

    self.addRepositoryEvent    = Event()
    self.removeRepositoryEvent = Event()
    self.changeRepositoryEvent = Event()
    self.applyButtonPressEvent = Event()

    self.rootWindow = rootWindow

    local listWindow = xrc.getWindow(rootWindow, 'listWindow')
    self.listWindow = listWindow

    self.listGrid = listWindow:GetSizer()

    local addRepositoryButton = xrc.getWindow(rootWindow, 'addRepositoryButton')
    utils.connect(addRepositoryButton, 'command_button_clicked', self.addRepositoryEvent)

    self.applyButton = xrc.getWindow(self.rootWindow, 'wxID_APPLY')
    utils.connect(self.applyButton, 'command_button_clicked', self.applyButtonPressEvent)

    return self
end
