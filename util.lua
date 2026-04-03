AH_CUT_MULTIPLIER = 0.95
BID_INCREMENT_MULTIPLIER = 1.05

function IsMat(itemId)
    return MAT[itemId] ~= nil
end

function IsProfessionItem(itemId)
    return LeatherworkingDB[itemId] ~= nil
        or TailoringDB[itemId] ~= nil
        or BlacksmithingDB[itemId] ~= nil
        or JewelcraftingDB[itemId] ~= nil
end

function IsItemFromList(itemId)
    return IsMat(itemId) or IsProfessionItem(itemId)
end

function GetMoneyString(money)
    local gold = floor(money / 10000)
    local silver = floor((money - gold * 10000) / 100)
    local copper = mod(money, 100)
    
    if gold > 0 then
        return format(GOLD_AMOUNT_TEXTURE.." "..SILVER_AMOUNT_TEXTURE.." "..COPPER_AMOUNT_TEXTURE, gold, 0, 0, silver, 0, 0, copper, 0, 0)
    elseif silver > 0 then
        return format(SILVER_AMOUNT_TEXTURE.." "..COPPER_AMOUNT_TEXTURE, silver, 0, 0, copper, 0, 0)
    else
        return format(COPPER_AMOUNT_TEXTURE, copper, 0, 0)
    end
end

function GetCost(itemId)
    local cost = 0
    
    if IsMat(itemId) then
        cost = MAT[itemId]
    elseif IsProfessionItem(itemId) then
        local recipe = LeatherworkingDB[itemId] or TailoringDB[itemId] or BlacksmithingDB[itemId] or JewelcraftingDB[itemId]
        
        for matId, quantity in pairs(recipe) do
            cost = cost + GetCost(matId) * quantity
        end
    end
    
    return cost
end

local function AddNonProfitPriceToTooltip(tooltip, itemId)
    local cost = GetCost(itemId)
    local price = cost / AH_CUT_MULTIPLIER
    local formattedCost = GetCoinTextureString(cost)
    local formattedPrice = GetCoinTextureString(price)
    
    tooltip:AddLine("ID: "..itemId, 1, 1, 1)
    tooltip:AddLine("COST: "..formattedCost, 1, 1, 1)
    tooltip:AddLine("NONPROFIT: "..formattedPrice, 1, 1, 1)
    tooltip:Show()
end

GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
    local _, itemLink = tooltip:GetItem()
    
    if itemLink then
        local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
        
        if itemID then
            AddNonProfitPriceToTooltip(tooltip, itemID)
        end
    end
end)

-- Helper function to extract item ID from hyperlink
function GetItemInfoFromHyperlink(hyperlink)
    if not hyperlink then return nil end
    local _, _, itemString = string.find(hyperlink, "|H(.+)|h%[.+%]")
    if itemString then
        local _, itemId = strsplit(":", itemString)
        return tonumber(itemId)
    end
    return nil
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function()
    print("|cff00ff00Wowcraft loaded!|r Type |cff00ff00/wowcraft|r to see commands")
end)

function ShowWowcraftHelp()
    print("|cff00ff00=== Wowcraft Commands ===|r")
    print("|cff00ff00/wowcraftui|r - Toggle Wowcraft window (Buy / Sell tabs)")
    print("|cff00ff00/postitems|r - Post crafted items (48h)")
    print("|cff00ff00/buybidmats [overbidProtection]|r - Bid on materials")
    print("  bid = buylist_price / overbidProtection")
    print("|cff00ff00/buybidall [overbidProtection]|r  - Bid on mats + crafted items")
    print("|cff00ff00/vendorbuy|r - Buy AH items below vendor price")
end
