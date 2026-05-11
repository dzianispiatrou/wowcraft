function IsItemFromBuylist(itemId)
    return MAT[itemId] ~= nil
end

function IsItemFromInternalBuylist(itemId)
 return INTERNAL_BUYLIST[itemId] ~= nil
end

function IsItemFromTailoring(itemId)
    return TAILORING[itemId] ~= nil
end

function IsItemFromLeatherworking(itemId)
    return LEATHERWORKING[itemId] ~= nil
end

function IsItemFromJewelcrafting(itemId)
    return JEWELCRAFTING[itemId] ~= nil
end

function IsItemFromBlacksmithing(itemId)
    return BLACKSMITHING[itemId] ~= nil
end

function IsItemFromCoin(itemId)
    return COIN[itemId] ~= nil
end

function IsCraftedItem(itemId)
    return LEATHERWORKING[itemId] ~= nil
        or TAILORING[itemId] ~= nil
        or BLACKSMITHING[itemId] ~= nil
        or JEWELCRAFTING[itemId] ~= nil
        or COIN[itemId] ~= nil
end

function GetItemSource(itemId)
    if IsItemFromInternalBuylist(itemId) then
        return "INTERNAL BUYLIST"
    elseif IsItemFromBuylist(itemId) then
        return "BUYLIST"
    elseif IsItemFromTailoring(itemId) then
        return "TAILORING"
    elseif IsItemFromLeatherworking(itemId) then
        return "LEATHERWORKING"
    elseif IsItemFromBlacksmithing(itemId) then
        return "BLACKSMITHING"
    elseif IsItemFromJewelcrafting(itemId) then
        return "JEWELCRAFTING"
    elseif IsItemFromCoin(itemId) then
        return "COIN"
    else
        return "UNKNOWN"
    end
end

function GetVendorPrice(itemId)
    local _, _, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(itemId)
    return vendorPrice
end

-- Calculates and returns item cost
-- Priority: internal buylist, buylist, craft cost, vendor
-- The craft cost equals the vendor price if the recipe uses unlisted mats
function GetItemCost(itemId)
    local vendorPrice = GetVendorPrice(itemId)
    local itemCost = 0
    
    if IsItemFromInternalBuylist(itemId) then
        return INTERNAL_BUYLIST[itemId]
    elseif IsItemFromBuylist(itemId) then
        return MAT[itemId]
    elseif IsCraftedItem(itemId) then
        local recipe = LEATHERWORKING[itemId] or TAILORING[itemId] or BLACKSMITHING[itemId] or JEWELCRAFTING[itemId]
        
        for matId, quantity in pairs(recipe) do
            local source = GetItemSource(matId)
            
            if source == "UNKNOWN" then
                return vendorPrice
            else
                itemCost = itemCost + GetItemCost(matId) * quantity
            end
        end
        return itemCost
    else
        return vendorPrice
    end
end
