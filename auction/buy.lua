local PURCHASE_FILTER = {
    all = IsItemFromList,
    mats = IsMat,
}

local sessionProfit = 0

local function getBidAmount(itemId, itemInfo, overbidProtection)
    --local _, _, count, _, _, _, minBid, minIncrement, buyoutPrice, bidAmount, highestBidder, _, _ = GetAuctionItemInfo("list", i)
    --local itemLink = GetAuctionItemLink("list", i)
    --local itemId = tonumber(itemLink:match("item:(%d+):"))
    
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
                BiddingQueue.push(string.format("%s: [%d] x [%s] = [%s] from [%s]", 
                    itemLink, itemInfo.count, GetMoneyString(amountToBid / itemInfo.count), 
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
                BiddingQueue.push(string.format("%s: [%d] x [%s] = [%s] from [%s]", 
                    itemLink, itemInfo.count, GetMoneyString(amountToBid / itemInfo.count), 
                    GetMoneyString(amountToBid), itemInfo.owner or ""))
                PlaceAuctionBid("list", i, amountToBid)
            end
    end
end
