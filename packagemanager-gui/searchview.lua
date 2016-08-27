local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local Event = require 'packagemanager-gui/event'
local Xrc   = require 'packagemanager-gui/xrc'


local SearchView = {}
SearchView.__index = SearchView

local StatusColumn  = 0
local NameColumn    = 1
local VersionColumn = 2

local PackageStatusToImageIdMap =
{
    ['available'] = 0,
    ['installed-updated'] = 1,
    ['install'] = 2,
    ['remove'] = 3
}

function SearchView:addResultEntry( packageStatus, packageName, packageVersion )
    local row = self.resultList:GetItemCount()
    local item = wx.wxListItem()
    item:SetId(row)
    self.resultList:InsertItem(item)

    self.resultList:SetItem(row, StatusColumn,  '', PackageStatusToImageIdMap[packageStatus])
    self.resultList:SetItem(row, NameColumn,    packageName)
    self.resultList:SetItem(row, VersionColumn, packageVersion)
end

function SearchView:adaptColumnWidths()
    self.resultList:SetColumnWidth(StatusColumn,  wx.wxLIST_AUTOSIZE)
    self.resultList:SetColumnWidth(NameColumn,    wx.wxLIST_AUTOSIZE)
    self.resultList:SetColumnWidth(VersionColumn, wx.wxLIST_AUTOSIZE)
end

function SearchView:clear()
    self.resultList:DeleteAllItems()
end

function SearchView:freeze()
    self.rootWindow:Freeze()
end

function SearchView:thaw()
    self.rootWindow:Thaw()
end

function SearchView:destroy()
    self.imageList:Destroy()
end

function SearchView:_setColumn( column, text, width )
    local item = wx.wxListItem()
    item:SetId(column)
    if text then
        item:SetText(text)
    end
    if width then
        item:SetWidth(width)
    end
    self.resultList:InsertColumn(column, item)
end

return function( rootWindow )
    local self = setmetatable({}, SearchView)

    self.rootWindow = rootWindow

    --local searchCtrl = Xrc.getWindow(self.rootWindow, 'searchCtrl')
    --local searchEditButton = Xrc.getWindow(self.rootWindow, 'searchEditButton')
    local resultList = Xrc.getWindow(self.rootWindow, 'searchResultList')
    self.resultList = resultList

    local imageClient = wx.wxART_MENU
    local size = wx.wxArtProvider.GetSizeHint(imageClient, true)
    local imageList = wx.wxImageList(size:GetWidth(), size:GetHeight())
    self.imageList = imageList

    imageList:Add(wx.wxArtProvider.GetIcon('package-available',         imageClient))
    imageList:Add(wx.wxArtProvider.GetIcon('package-installed-updated', imageClient))
    imageList:Add(wx.wxArtProvider.GetIcon('package-install',           imageClient))
    imageList:Add(wx.wxArtProvider.GetIcon('package-remove',            imageClient))
    resultList:SetImageList(imageList, wx.wxIMAGE_LIST_SMALL)

    self:_setColumn(StatusColumn)
    self:_setColumn(NameColumn,    'Name')
    self:_setColumn(VersionColumn, 'Version')

    return self
end
