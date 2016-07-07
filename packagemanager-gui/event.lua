local Event = {}
Event.__index = Event

function Event:addListener( fn )
    self.listeners[fn] = true
end

function Event:removeListener( fn )
    self.listeners[fn] = nil
end

function Event:__call( ... )
    for fn, _ in pairs(self.listeners) do
        fn(...)
    end
end

return function()
    return setmetatable({ listeners={} }, Event)
end
