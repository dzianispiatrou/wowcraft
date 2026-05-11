local function getBidAmount(itemCost, itemInfo, overbidProtection)
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
        
        if IsItemFromInternalBuylist(itemId) or IsItemFromBuylist(itemId) then
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
            local cost = GetItemCost(itemId)
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

local function Buy(msg, includeCrafted)
    if not AuctionFrame or not AuctionFrame:IsShown() then
        return
    end
    
    BiddingQueue.reset()

    local overbidProtection = tonumber(msg) or BID_INCREMENT_MULTIPLIER
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
        
        local itemCost = GetVendorPrice(itemId)
        
        if IsItemFromBuylist(itemId) or IsItemFromInternalBuylist(itemId) or includeCrafted then
            itemCost = GetItemCost(itemId)
        end
        local amountToBid = getBidAmount(itemCost, itemInfo, overbidProtection)
            
        if amountToBid then
            BiddingQueue.push(string.format("[%d] - %s: [%d] x [%s] = [%s] from [%s]", 
                i, itemLink, itemInfo.count, GetMoneyString(amountToBid / itemInfo.count), 
                GetMoneyString(amountToBid), itemInfo.owner or ""))
            PlaceAuctionBid("list", i, amountToBid)
        end
        
    end
end

function BuyAll(msg)
    Buy(msg, true)
end

function BuyMats(msg)
    Buy(msg, false)
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
            
            
            local itemCost = GetItemCost(itemId)
            local amountToBid = getBidAmount(itemCost, itemInfo, overbidProtection)
            local vendorPrice = GetVendorPrice(itemId)
            
            if amountToBid and itemCost == vendorPrice then
                BiddingQueue.push(string.format("[%d] - %s: [%d] x [%s] = [%s] from [%s]", 
                    i, itemLink, itemInfo.count, GetMoneyString(amountToBid / itemInfo.count), 
                    GetMoneyString(amountToBid), itemInfo.owner or ""))
                PlaceAuctionBid("list", i, amountToBid)
            end
    end
end

function AppraiseBids()
    if not AuctionFrame or not AuctionFrame:IsShown() then
        return
    end
    
    local numAuctionBids = GetNumAuctionItems("bidder")
    local totalBidAmount = 0
    local totalBuylistCost = 0
    local totalLoss = 0
    
    for i = 1, numAuctionBids do
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
        itemInfo.sold = GetAuctionItemInfo("bidder", i)
        
        local currentBid = itemInfo.bidAmount
        totalBidAmount = totalBidAmount + currentBid
        
        local itemLink = GetAuctionItemLink("bidder", i)
        local itemId = tonumber(itemLink:match("item:(%d+):"))
        local currentBuylistCost = GetItemCost(itemId) * itemInfo.count
        totalBuylistCost = totalBuylistCost + currentBuylistCost
       
        if currentBid > currentBuylistCost then
            local delta = currentBid - currentBuylistCost
            totalLoss = totalLoss + delta
            print(string.format("%s bid: %s buylist: %s delta: %s",itemLink, GetMoneyString(currentBid), GetMoneyString(currentBuylistCost), GetMoneyString(delta)))
        end
    end
    
    print(string.format("%s is wasted on bids", GetMoneyString(totalBidAmount)))
    print(string.format("%s is their buylist price", GetMoneyString(totalBuylistCost)))
    print(string.format("%s is total loss", GetMoneyString(totalLoss)))
end