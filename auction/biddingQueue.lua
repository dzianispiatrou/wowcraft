BiddingQueue = {first = 0, last = -1}

function BiddingQueue.push(value)
    local first = BiddingQueue.first - 1
    BiddingQueue.first = first
    BiddingQueue[first] = value
end

function BiddingQueue.pop()
    local last = BiddingQueue.last
    if BiddingQueue.first > last then return nil end
    local value = BiddingQueue[last]
    BiddingQueue[last] = nil
    BiddingQueue.last = last - 1
    return value
end

function BiddingQueue.reset()
    BiddingQueue.first = 0
    BiddingQueue.last = -1
end

local frame = CreateFrame("FRAME")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:SetScript("OnEvent", function(self, event, message)
    if string.find(message, "Bid accepted.") then
        print(BiddingQueue.pop())
    end
end)
