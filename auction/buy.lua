local PURCHASE_FILTER = {
    all = IsItemFromList,
    mats = IsMat,
}

local sessionProfit = 0

currentItemIndex = 1

local function getBidAmount(itemId, itemInfo, overbidProtection)
    local _, itemCost = GetCost(itemId)
    local maxPrice = itemCost * itemInfo.count
    local nextBid = math.max(itemInfo.minBid, itemInfo.bidAmount) + itemInfo.minIncrement
    
    if 0 < itemInfo.buyoutPrice and itemInfo.buyoutPrice <= maxPrice then
        return itemInfo.buyoutPrice
    end
    
    if nextBid > maxPrice or itemInfo.highestBidder then
        return
    end
    
    local safeBid = maxPrice / overbidProtection
    
    if itemInfo.buyoutPrice == 0 then
        return math.max(safeBid, nextBid)
    end
    
    return math.max(math.min(safeBid, itemInfo.buyoutPrice / BID_INCREMENT_MULTIPLIER), nextBid)
end

function EstimateProfit()
    if not AuctionFrame or not AuctionFrame:IsShown() then
        return
    end
    
    local totalCost = 0
    local totalPrice = 0
    local totalBidCost = 0
    local totalBidPrice = 0
    local numAuctionItems = GetNumAuctionItems("list")
    
    for i = 1, numAuctionItems do
        local itemLink = GetAuctionItemLink("list", i)
        local itemId = tonumber(itemLink:match("item:(%d+):"))
        
        if IsMat(itemId) then
            local itemInfo = {}
            itemInfo.name, 
            itemInfo.texture, 
            itemInfo.count,
            itemInfo.quality, 
            itemInfo.canUse, 
            itemInfo.level, 
            itemInfo.minBid, 
            itemInfo.minIncrement, 
            itemInfo.buyoutPrice, 
            itemInfo.bidAmount, 
            itemInfo.highestBidder, 
            itemInfo.owner, 
            itemInfo.sold = GetAuctionItemInfo("list", i)
            local _, cost = GetCost(itemId)
            local maxPrice = cost * itemInfo.count
            
            if 0 < itemInfo.buyoutPrice and itemInfo.buyoutPrice <= maxPrice then
                totalCost = totalCost + cost * itemInfo.count
                totalPrice = totalPrice + itemInfo.buyoutPrice
            else
                local amountToBid = getBidAmount(itemId, itemInfo, 1.025)
                
                if amountToBid then
                    totalBidPrice = totalBidPrice + amountToBid
                    totalBidCost = totalBidCost + cost * itemInfo.count
                end
            end
        end
    end
    
    local totalProfit = totalCost - totalPrice
    local profitInPercentages = 0
    
    if totalPrice ~= 0 then
        profitInPercentages = totalProfit * 100.0 / totalPrice
    end
    print(format("AH PRICE: [%s] CARTEL PRICE: [%s] PROFIT: [%s] (%f%s)", GetMoneyString(totalPrice), GetMoneyString(totalCost), GetMoneyString(totalProfit), profitInPercentages, "%"))
    
    
    local totalBidProfit = totalBidCost - totalBidPrice
    local bidProfitInPercentages = 0
    
    if totalBidPrice ~= 0 then
        bidProfitInPercentages = totalBidProfit * 100.0 / totalBidPrice
    end
    print(format("AH BID PRICE: [%s] CARTEL PRICE: [%s] PROFIT: [%s] (%f%s)", GetMoneyString(totalBidPrice), GetMoneyString(totalBidCost), GetMoneyString(totalBidProfit), bidProfitInPercentages, "%"))
    local moneyLeft = GetMoney()-totalBidPrice-totalPrice
    if moneyLeft >= 0 then
        print(GetMoneyString(moneyLeft))
    else
        print(format("-%s", GetMoneyString(-moneyLeft)))
    end
end

local function Buy(msg, filterType)
    if not AuctionFrame or not AuctionFrame:IsShown() then
        return
    end
    
    BiddingQueue.reset()

    local overbidProtection = tonumber(msg) or BID_INCREMENT_MULTIPLIER
    local numAuctionItems = GetNumAuctionItems("list")
    local filterFunc = PURCHASE_FILTER[filterType]
    
    for i = 1, numAuctionItems do
        local itemLink = GetAuctionItemLink("list", i)
        local itemId = tonumber(itemLink:match("item:(%d+):"))
        
        if filterFunc(itemId) then
            local itemInfo = {}
            itemInfo.name, 
            itemInfo.texture, 
            itemInfo.count,
            itemInfo.quality, 
            itemInfo.canUse, 
            itemInfo.level, 
            itemInfo.minBid, 
            itemInfo.minIncrement, 
            itemInfo.buyoutPrice, 
            itemInfo.bidAmount, 
            itemInfo.highestBidder, 
            itemInfo.owner, 
            itemInfo.sold = GetAuctionItemInfo("list", i)
            local amountToBid = getBidAmount(itemId, itemInfo, overbidProtection)
            
            if amountToBid then
                BiddingQueue.push(string.format("[%d] - %s: [%d] x [%s] = [%s] from [%s]", 
                    i, itemLink, itemInfo.count, GetMoneyString(amountToBid / itemInfo.count), 
                    GetMoneyString(amountToBid), itemInfo.owner or ""))
                PlaceAuctionBid("list", i, amountToBid)
            end
        end
    end
end

function BuyAll(msg)
    Buy(msg, "all")
end

function BuyMats(msg)
    Buy(msg, "mats")
end

function BuyToVendor()
    if not AuctionFrame or not AuctionFrame:IsShown() then
        return
    end
    
    BiddingQueue.reset()
    
    local overbidProtection = 2
    
    local numAuctionItems = GetNumAuctionItems("list")
    
    for i = 1, numAuctionItems do
        local itemLink = GetAuctionItemLink("list", i)
        local itemId = tonumber(itemLink:match("item:(%d+):"))
        local itemInfo = {}
            itemInfo.name, 
            itemInfo.texture, 
            itemInfo.count,
            itemInfo.quality, 
            itemInfo.canUse, 
            itemInfo.level, 
            itemInfo.minBid, 
            itemInfo.minIncrement, 
            itemInfo.buyoutPrice, 
            itemInfo.bidAmount, 
            itemInfo.highestBidder, 
            itemInfo.owner, 
            itemInfo.sold = GetAuctionItemInfo("list", i)
            
            local amountToBid = getBidAmount(itemId, itemInfo, overbidProtection)
            local reason, cost = GetCost(itemId)
            
            if amountToBid and reason == "VENDOR" then
                BiddingQueue.push(string.format("[%d] - %s: [%d] x [%s] = [%s] from [%s]", 
                    i, itemLink, itemInfo.count, GetMoneyString(amountToBid / itemInfo.count), 
                    GetMoneyString(amountToBid), itemInfo.owner or ""))
                PlaceAuctionBid("list", i, amountToBid)
            end
    end
end

function OneClickOneBid(msg)
    if not AuctionFrame or not AuctionFrame:IsShown() then
        return
    end
    
    BiddingQueue.reset()

    local overbidProtection = tonumber(msg) or BID_INCREMENT_MULTIPLIER
    local numAuctionItems = GetNumAuctionItems("list")
    local filterFunc = IsMat
    
    --for i = 1, numAuctionItems do
        local itemLink = GetAuctionItemLink("list", currentItemIndex)
        local itemId = tonumber(itemLink:match("item:(%d+):"))
        
        if filterFunc(itemId) then
            local itemInfo = {}
            itemInfo.name, 
            itemInfo.texture, 
            itemInfo.count,
            itemInfo.quality, 
            itemInfo.canUse, 
            itemInfo.level, 
            itemInfo.minBid, 
            itemInfo.minIncrement, 
            itemInfo.buyoutPrice, 
            itemInfo.bidAmount, 
            itemInfo.highestBidder, 
            itemInfo.owner, 
            itemInfo.sold = GetAuctionItemInfo("list", currentItemIndex)
            local amountToBid = getBidAmount(itemId, itemInfo, overbidProtection)
            
            if amountToBid then
                BiddingQueue.push(string.format("[%d] - %s: [%d] x [%s] = [%s] from [%s]", 
                    currentItemIndex, itemLink, itemInfo.count, GetMoneyString(amountToBid / itemInfo.count), 
                    GetMoneyString(amountToBid), itemInfo.owner or ""))
                PlaceAuctionBid("list", currentItemIndex, amountToBid)
            end
        end
        
        currentItemIndex = currentItemIndex + 1
        print(format("current index = %d", currentItemIndex))
    --end
end

function ResetIndex()
    currentItemIndex = 1
    print(format("current index = %d", currentItemIndex))
end

local frame = CreateFrame("FRAME")
frame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "AUCTION_ITEM_LIST_UPDATE" then
        --currentItemIndex = 1
        --print("currentItemIndex set to 1")
    end
end)