local StatusBarPresenter = {}
StatusBarPresenter.__index = StatusBarPresenter

function StatusBarPresenter:destroy()
end

return function( view )
    local self = setmetatable({}, StatusBarPresenter)
    self.view = view
    return self
end
