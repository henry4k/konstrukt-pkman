local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local Event = require 'packagemanager-gui/Event'
local xrc   = require 'packagemanager-gui/xrc'


local SearchView = {}
SearchView.__index = SearchView

function SearchView:getQuery()
    return self.searchCtrl:GetValue()
end

function SearchView:setQuery( query )
    self.searchCtrl:ChangeValue(query)
end

local StatusColumn  = 0
local NameColumn    = 1
local VersionColumn = 2

local SortModeToImageIdMap =
{
    none = -1,
    ascending  = 0,
    descending = 1
}

local PackageStatusToImageIdMap =
{
    ['available']         = 2,
    ['installed-updated'] = 3,
    ['install']           = 4,
    ['remove']            = 5
}

function SearchView:addResultEntry( packageStatus, packageName, packageVersion )
    local row = self.resultList:GetItemCount()
    local item = wx.wxListItem()
    item:SetId(row)
    self.resultList:InsertItem(item)

    self.resultList:InsertItem(row, StatusColumn,  '', PackageStatusToImageIdMap[packageStatus])
    self.resultList:SetItem(   row, NameColumn,    packageName)
    self.resultList:SetItem(   row, VersionColumn, packageVersion)
    self:adaptColumnWidths()
end

function SearchView:adaptColumnWidths()
    local list = self.resultList
    for i = 0, list:GetColumnCount()-1 do
        list:SetColumnWidth(i, wx.wxLIST_AUTOSIZE_USEHEADER)
        local headerWidth = list:GetColumnWidth(i)

        list:SetColumnWidth(i, wx.wxLIST_AUTOSIZE)
        local itemWidth = list:GetColumnWidth(i)

        list:SetColumnWidth(i, math.max(headerWidth, itemWidth))
    end
end

function SearchView:sort( column, mode )
    local list = self.resultList
    local item = wx.wxListItem()
    for i = 0, list:GetColumnCount()-1 do
        local imageId
        if i == column then
            imageId = SortModeToImageIdMap[mode]
        else
            imageId = SortModeToImageIdMap.none
        end
        item:SetImage(imageId)
        item:SetMask(wx.wxLIST_MASK_IMAGE)
        list:SetColumn(i, item)
    end
    item:delete()
    --list:SortItems()
end

function SearchView:clearResults()
    self.resultList:DeleteAllItems()
end

function SearchView:freeze()
    self.rootWindow:Freeze()
end

function SearchView:thaw()
    self.rootWindow:Thaw()
end

function SearchView:destroy()
end

function SearchView:_setColumn( column, text )
    local item = wx.wxListItem()
    item:SetId(column)
    if text then
        item:SetText(text)
    end
    self.resultList:InsertColumn(column, item)
end

return function( rootWindow )
    local self = setmetatable({}, SearchView)

    self.searchChangeEvent = Event()
    self.searchEditEvent   = Event()
    self.columnClickEvent  = Event()

    self.rootWindow = rootWindow

    local searchCtrl = xrc.getWindow(self.rootWindow, 'searchCtrl')
    self.searchCtrl = searchCtrl
    utils.connect(searchCtrl, 'command_text_updated', self.searchChangeEvent)

    local searchEditButton = xrc.getWindow(self.rootWindow, 'searchEditButton')
    utils.connect(searchEditButton, 'command_button_clicked', self.searchEditEvent)

    local resultList = xrc.getWindow(self.rootWindow, 'searchResultList')
    self.resultList = resultList

    local imageClient = wx.wxART_MENU
    local size = wx.wxArtProvider.GetSizeHint(imageClient, true)
    local imageList = wx.wxImageList(size:GetWidth(), size:GetHeight())
    self.imageList = imageList

    imageList:Add(wx.wxArtProvider.GetIcon('sort-ascending',            imageClient))
    imageList:Add(wx.wxArtProvider.GetIcon('sort-descending',           imageClient))
    imageList:Add(wx.wxArtProvider.GetIcon('package-available',         imageClient))
    imageList:Add(wx.wxArtProvider.GetIcon('package-installed-updated', imageClient))
    imageList:Add(wx.wxArtProvider.GetIcon('package-install',           imageClient))
    imageList:Add(wx.wxArtProvider.GetIcon('package-remove',            imageClient))
    resultList:SetImageList(imageList, wx.wxIMAGE_LIST_SMALL)

    self:_setColumn(StatusColumn)
    self:_setColumn(NameColumn,    'Name')
    self:_setColumn(VersionColumn, 'Version')
    self:sort(NameColumn, 'ascending')
    self:adaptColumnWidths()

    utils.connect(resultList, 'command_list_col_click', function()
        local column = e:GetColumn()
        self.columnClickEvent(column)
    end)

    return self
end
