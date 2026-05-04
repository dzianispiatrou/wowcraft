function IsItemFromBuylist(itemId)
    return MAT[itemId] ~= nil
end

function IsItemFromInternalBuylist(itemId)
 return INTERNAL_BUYLIST[itemId] ~= nil
end

function IsItemFromTailoring(itemId)
    return TailoringDB[itemId] ~= nil
end

function IsItemFromLeatherworking(itemId)
    return LeatherworkingDB[itemId] ~= nil
end

function IsItemFromJewelcrafting(itemId)
    return JewelcraftingDB[itemId] ~= nil
end

function IsItemFromBlacksmithing(itemId)
    return BlacksmithingDB[itemId] ~= nil
end

function IsCraftedItem(itemId)
    return LeatherworkingDB[itemId] ~= nil
        or TailoringDB[itemId] ~= nil
        or BlacksmithingDB[itemId] ~= nil
        or JewelcraftingDB[itemId] ~= nil
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
    else
        return "UNKNOWN"
    end
end

-- Calculates and returns item cost
-- Priority: internal buylist, buylist, craft cost, vendor
-- The craft cost equals the vendor price if the recipe uses unlisted mats
function GetItemCost(itemId)
    local _, _, _, _, _, _, _, _, _, _, vendorPrice = GetItemInfo(itemId)
    local itemCost = 0
    
    if IsItemFromInternalBuylist(itemId) then
        return INTERNAL_BUYLIST[itemId]
    elseif IsItemFromBuylist(itemId) then
        return MAT[itemId]
    elseif IsCraftedItem(itemId) then
        local recipe = LeatherworkingDB[itemId] or TailoringDB[itemId] or BlacksmithingDB[itemId] or JewelcraftingDB[itemId]
        
        for matId, quantity in pairs(recipe) do
            local source = GetItemSource(matId)
            
            if source == "UNKNOWN" then
                return vendorPrice
            else
                cost = cost + matCost * quantity
            end
        end
    end
end
