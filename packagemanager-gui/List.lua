local wx = require 'wx'
local utils = require 'packagemanager-gui/utils'
local Event = require 'packagemanager-gui/Event'


local List = {}
List.__index = List

function List:_prepareItem( item, column, columnData )
    local imageId = -1
    if columnData.icon then
        imageId = assert(self.imageIdMap[columnData.icon])
    end

    item:SetColumn(column-1)
    item:SetImage(imageId)
    item:SetText(columnData.text or '')
end

---
-- @param[type=table] columns
-- A list, which holds these properties for each column:
--
-- - `icon` (Optional)
-- - `text` (Optional)
-- - `value` (Optional)
--
function List:addRow( columns )
    local window = self.window
    local index = window:GetItemCount()

    local item = wx.wxListItem()
    item:SetId(index)
    item:SetData(index+1)
    self:_prepareItem(item, 1, columns[1])
    assert(window:InsertItem(item))
    for i = 2, #columns do
        self:_prepareItem(item, i, columns[i])
        window:SetItem(item)
    end
    item:delete()

    local value = {}
    for i = 1, #columns do
        value[i] = columns[i].value
    end
    table.insert(self.rows, value)
end

function List:clear()
    self.window:DeleteAllItems()
    self.rows = {}
end

function List:destroy()
end

function List:_setupImageList( icons )
    local imageClient = wx.wxART_MENU
    local size = wx.wxArtProvider.GetSizeHint(imageClient, true)
    local imageList = wx.wxImageList(size:GetWidth(), size:GetHeight())
    self.imageList = imageList

    local imageIdMap = {}
    self.imageIdMap = imageIdMap

    local nextImageId = 0
    local function addIcon( iconName )
        if not imageIdMap[iconName] then
            local icon = wx.wxArtProvider.GetIcon(iconName, imageClient)
            imageList:Add(icon)
            imageIdMap[iconName] = nextImageId
            nextImageId = nextImageId + 1
        end
    end

    addIcon('sort-ascending')
    addIcon('sort-descending')
    for _, iconName in ipairs(icons or {}) do
        addIcon(iconName)
    end

    self.window:SetImageList(imageList, wx.wxIMAGE_LIST_SMALL)
end

function List:_setupColumns( columns )
    local sortableColumns = {}
    self.sortableColumns = sortableColumns

    for i, column in ipairs(columns) do
        sortableColumns[i] = column.sortable or true

        local item = wx.wxListItem()
        if column.label then
            item:SetText(column.label)
        end
        self.window:InsertColumn(i-1, item)
    end
end

function List:sort( columnIndex, mode )
    columnIndex = columnIndex or self.currentlySortedColumn
    mode = mode or self.currentSortMode

    if not self.sortableColumns[columnIndex] then
        return false
    end

    local window = self.window
    local item = wx.wxListItem()
    for i = 1, window:GetColumnCount() do
        local imageId
        if i == columnIndex then
            imageId = self.imageIdMap['sort-'..mode]
        else
            imageId = -1
        end
        item:SetImage(imageId)
        item:SetMask(wx.wxLIST_MASK_IMAGE)
        window:SetColumn(i-1, item)
    end
    item:delete()

    local modificator
    if mode == 'ascending' then
        modificator = 1
    elseif mode == 'descending' then
        modificator = -1
    else
        error('Unknown sort mode.')
    end

    local function comparator( aIndex, bIndex )
        local rows = self.rows
        local a = rows[aIndex][columnIndex]
        local b = rows[bIndex][columnIndex]
        if a == b then
            return 0
        else
            if a < b then
                return -1*modificator
            else
                return  1*modificator
            end
        end
    end

    assert(window:SortItems(utils.wrapCallbackForWx(comparator), 0))

    self.currentlySortedColumn = columnIndex
    self.currentSortMode = mode

    return true
end

function List:adaptColumnWidths()
    local window = self.window
    for i = 0, window:GetColumnCount()-1 do
        window:SetColumnWidth(i, wx.wxLIST_AUTOSIZE_USEHEADER)
        local headerWidth = window:GetColumnWidth(i)

        window:SetColumnWidth(i, wx.wxLIST_AUTOSIZE)
        local itemWidth = window:GetColumnWidth(i)

        window:SetColumnWidth(i, math.max(headerWidth, itemWidth))
    end
end

function List:freeze()
    self.window:Freeze()
end

function List:thaw()
    self.window:Thaw()
end

---
-- @param[type=table] columns
-- A list of column definitions, which have these properties:
--
-- - `label`: (Optional)
-- - `comparator`: Comparision function, which enables the user to sort the columns. (Optional)
--
-- @param[type=table] icons
-- A list of icon names, which shall be available for entries.
--
return function( listWindow, columns, icons )
    local self = setmetatable({}, List)
    self.window = listWindow
    self.rows = {}
    self:_setupImageList(icons)
    self:_setupColumns(columns)

    self.currentlySortedColumn = -1
    self.currentSortMode = ''

    utils.connect(listWindow, 'command_list_col_click', function(e)
        local column = e:GetColumn() + 1

        local sortMode
        if column == self.currentlySortedColumn then
            if self.currentSortMode == 'ascending' then
                sortMode = 'descending'
            else
                sortMode = 'ascending'
            end
        else
            sortMode = 'ascending'
        end

        self:sort(column, sortMode)
        self:adaptColumnWidths()
    end)

    return self
end
