local bind = require('packagemanager/misc').bind
local Timer = require 'packagemanager-gui/Timer'


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
    local text = nil
    for _, source in ipairs(self.sourceList) do
        local sourceText = self.sourceTexts[source]
        if sourceText then
            text = sourceText
            break
        end
    end

    if text then
        self.view:freeze()
        self.view:setText(text)
        self.view:thaw()
        self.clearTimer:stop()
    else
        if not self.clearTimer.running then
            self.clearTimer:startOnce(3)
        end
    end
end

function StatusBarPresenter:_onClearTimerTriggered()
    self.view:freeze()
    self.view:setText('')
    self.view:thaw()
end

function StatusBarPresenter:destroy()
    self.clearTimer:destroy()
end

return function( view )
    local self = setmetatable({}, StatusBarPresenter)
    self.view = view
    self.clearTimer = Timer(bind(StatusBarPresenter._onClearTimerTriggered, self))
    self:defineSources{'changes', 'indices'}
    self:_update()
    return self
end
