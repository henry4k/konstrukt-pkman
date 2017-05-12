local MovingAverage = {}
MovingAverage.__index = MovingAverage

function MovingAverage:calculate( newAmount )
    local s = self.smoothingFactor
    local r = newAmount*(1-s) + self.currentAverage*s
    self.currentAverage = r
    return r
end

local function CreateMovingAverage( smoothingFactor )
    local self = { currentAverage = 0,
                   smoothingFactor = smoothingFactor or 0.9 }
    return setmetatable(self, MovingAverage)
end


local RateCalculator = {}
RateCalculator.__index = RateCalculator

function RateCalculator:update( amount )
    local currentRate = (amount-self._lastAmount) / self._updateFrequency
    self.rate = currentRate
    self._lastAmount = amount

    local averageRate = self._movingAverage:calculate(currentRate)
    if averageRate > 0 then
        local amountLeft = self.totalAmount - amount
        local eta = amountLeft / averageRate
        self.eta = eta
    else
        self.eta = nil
    end
end

function RateCalculator:getAverageRate()
    return self._movingAverage.currentAverage
end

return function( totalAmount, updateFrequency, smoothingFactor )
    local self = { totalAmount = totalAmount,
                   _lastAmount = 0,
                   _updateFrequency = updateFrequency,
                   rate = 0,
                   eta = nil, -- nil means unknown
                   _movingAverage = CreateMovingAverage(smoothingFactor) }
    return setmetatable(self, RateCalculator)
end
