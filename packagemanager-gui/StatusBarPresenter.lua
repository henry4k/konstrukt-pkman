local StatusBarPresenter = {}
StatusBarPresenter.__index = StatusBarPresenter

function StatusBarPresenter:defineSources( sourceList )
    self.sourceList = sourceList
    self.sourceTexts = {}
end

function StatusBarPresenter:setMessage( source, message )
    local sourceOk = false
    for _, aSource in ipairs(self.sourceList) do
        if source == aSource then
            sourceOk = true
            break
        end
    end
    assert(sourceOk, 'Source has not been defined.')
    self.sourceTexts[source] = message
    self:_update()
end

function StatusBarPresenter:_update()
    local text = ''
    for _, source in ipairs(self.sourceList) do
        local sourceText = self.sourceTexts[source]
        if sourceText then
            text = sourceText
            break
        end
    end
    self.view:freeze()
    self.view:setText(text)
    self.view:thaw()
end

function StatusBarPresenter:destroy()
end

return function( view )
    local self = setmetatable({}, StatusBarPresenter)
    self.view = view
    self:defineSources{'changes', 'indices'}
    self:_update()
    return self
end
