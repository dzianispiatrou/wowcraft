local DURATION = 3  -- 3 = 48 hours

-- Function to post BoE items from bags
function PostItems()
    for bag = 0, 3 do
        local numSlots = GetContainerNumSlots(bag)
        
        for slot = 1, numSlots do
            local itemLink = GetContainerItemLink(bag, slot)
            
            if itemLink then
                local itemId = GetItemInfoFromHyperlink(itemLink)
                
                if not IsMat(itemId) and IsProfessionItem(itemId) then
                    local _, cost = GetCost(itemId)
                    price = cost / AH_CUT_MULTIPLIER
                    local _, itemCount, _, _, _, _, _ = GetContainerItemInfo(bag, slot)
                    local stackSize = 1
                    local randomProfit = math.random(0,10000)
                    PickupContainerItem(bag, slot)
                    ClickAuctionSellItemButton()
                    ClearCursor()
                    StartAuction(price + randomProfit, price + randomProfit, DURATION, stackSize, itemCount)
                    print(format("%s %s x %d", itemLink, GetMoneyString(price + randomProfit), itemCount))
                end
            end
        end
    end
end
