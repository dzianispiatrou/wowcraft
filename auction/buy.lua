local PURCHASE_FILTER = {
    all = IsItemFromList,
    mats = IsMat,
}

local sessionProfit = 0

local function getBidAmount(i, overbidProtection)
    local _, _, count, _, _, _, minBid, minIncrement, buyoutPrice, bidAmount, highestBidder, _, _ = GetAuctionItemInfo("list", i)
    local itemLink = GetAuctionItemLink("list", i)
    local itemId = tonumber(itemLink:match("item:(%d+):"))
    
    local itemCost = GetCost(itemId)
    local nextBid = math.max(minBid, bidAmount) + minIncrement
    local nextBidCost = nextBid / count
    
    local buyoutCost = buyoutPrice / count
    
    if 0 < buyoutCost and buyoutCost <= itemCost  then
        return buyoutPrice
    end
    
    if nextBidCost > itemCost then
        return
    end
    
    if highestBidder then
        return
    end
    
    local safeBid = count * itemCost / overbidProtection
    
    if buyoutPrice == 0 then
        return math.max(safeBid, nextBid)
    end
    
    return math.max(math.min(safeBid, buyoutPrice / BID_INCREMENT_MULTIPLIER), nextBid)
end

local function Buy(msg, filterType)
    if not AuctionFrame or not AuctionFrame:IsShown() then
        return
    end
    
    biddingQueue:Reset()

    local overbidProtection = tonumber(msg) or BID_INCREMENT_MULTIPLIER
    local numAuctionItems = GetNumAuctionItems("list")
    local filterFunc = PURCHASE_FILTER[filterType]
    
    for i = 1, numAuctionItems do
        local itemLink = GetAuctionItemLink("list", i)
        local itemId = tonumber(itemLink:match("item:(%d+):"))
        
        if filterFunc(itemId) then
            local _, _, count, _, _, _, _, _, buyoutPrice, _, _, owner, _ = GetAuctionItemInfo("list", i)
            local amountToBid = getBidAmount(i, overbidProtection)
            
            if amountToBid then
                biddingQueue:Push(string.format("%s: [%d] x [%s] = [%s] from [%s]", 
                    itemLink, count, GetMoneyString(amountToBid / count), 
                    GetMoneyString(amountToBid), owner or "noname"))
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
    
    biddingQueue:Reset()
    
    local numAuctionItems = GetNumAuctionItems("list")
    
    for i = 1, numAuctionItems do
        local itemLink = GetAuctionItemLink("list", i)
        local itemId = tonumber(itemLink:match("item:(%d+):"))
        local _, _, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(itemId)
        local _, _, count, _, _, _, _, _, buyoutPrice, _, _, owner, _ = GetAuctionItemInfo("list", i)
        
        if buyoutPrice > 0 and vendorPrice > 0 and vendorPrice * count >= buyoutPrice then
            biddingQueue:Push(string.format("%s: [%d] x [%s] = [%s] from [%s] profit [%s]", itemLink, count, GetMoneyString(buyoutPrice / count), GetMoneyString(buyoutPrice), owner or "noname", GetMoneyString(vendorPrice * count - buyoutPrice)))
            PlaceAuctionBid("list", i, buyoutPrice)
        end
    end
end
