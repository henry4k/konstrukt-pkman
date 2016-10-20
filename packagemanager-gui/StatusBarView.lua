local StatusBarView = {}
StatusBarView.__index = StatusBarView

function StatusBarView:addField( text )
    local field = {}
    field.index = #self.fieldList+1
    field.text = text

    self.fields[field] = field
    self.fieldList[field.index] = field

    self:_updateFieldsByFieldList()
    return field
end

function StatusBarView:_updateFieldsByFieldList()
    self.window:SetFieldsCount(#self.fieldList)
    for i, field in ipairs(self.fieldList) do
        self.window:SetStatusText(field.text, i-1)
    end
end

function StatusBarView:removeField( field )
    assert(self.fields[field])
    self.fields[field] = nil
    table.remove(self.fieldList, field.index)
    self:_updateFieldsByFieldList()
end

function StatusBarView:setFieldText( field, text )
    assert(self.fields[field])
    field.text = text
    self.window:SetStatusText(text, field.index-1)
end

function StatusBarView:destroy()
end

return function( window )
    local self = setmetatable({}, StatusBarView)
    self.window = window
    self.fields = {}
    self.fieldList = {}
    return self
end
