local RingBuffer = require 'packagemanager-cli/RingBuffer'


local function CalcSum( values )
    local sum = 0
    for _, value in ipairs(values) do
        sum = sum + value
    end
    return sum
end

local function CalcStandardDeviation( values, sum )
    local average = sum / #values
    local tmp = 0
    for _, value in ipairs(values) do
        tmp = tmp + (value - average)
    end
    local variance = tmp / #values
    return math.sqrt(variance)
end


local RateCalculator = {}
RateCalculator.__index = RateCalculator

function RateCalculator:_updateAverageRate( currentRate )
    self._buffer:append(currentRate)

    local sum = CalcSum(self._buffer)
    local stdDeviation = CalcStandardDeviation(self._buffer, sum)
    local scaling = (self.totalAmount - self._lastAmount) / self._lastAmount

    local lowerBound = sum*scaling - 3*stdDeviation*math.sqrt(scaling)
    local upperBound = sum*scaling + 3*stdDeviation*math.sqrt(scaling)

    local averageRate = lowerBound + (upperBound-lowerBound)/2
    self._averageRate = averageRate
end

function RateCalculator:update( amount )
    local currentRate = (amount-self._lastAmount) / self._updateFrequency
    self.rate = currentRate
    self._lastAmount = amount

    self:_updateAverageRate(currentRate)
    local averageRate = self._averageRate
    if averageRate > 0 then
        local amountLeft = self.totalAmount - amount
        local eta = amountLeft / averageRate
        self.eta = eta
    else
        self.eta = nil
    end
end

function RateCalculator:getAverageRate()
    return self._averageRate -- TODO: This is a lie!
end

return function( totalAmount, updateFrequency, smoothingFactor )
    local self = { totalAmount = totalAmount,
                   _lastAmount = 0,
                   _updateFrequency = updateFrequency,
                   rate = 0,
                   eta = nil, -- nil means unknown
                   _buffer = RingBuffer(bufferSize) }
    return setmetatable(self, RateCalculator)
end
