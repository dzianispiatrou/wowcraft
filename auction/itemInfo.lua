local ITEM_SOURCE = {
    BUYLIST = "BUYLIST",
    LEATHERWORKING = "LEATHERWORKING",
    TAILORING = "TAILORING",
    BLACKSMITHING = "BLACKSMITHING",
    JEWELCRAFTING = "JEWELCRAFTING",
    VENDOR = "VENDOR"
}

local SOURCE_ORDER = {
    {check = MAT, source = ITEM_SOURCE.BUYLIST},
    {check = LeatherworkingDB, source = ITEM_SOURCE.LEATHERWORKING},
    {check = TailoringDB, source = ITEM_SOURCE.TAILORING},
    {check = BlacksmithingDB, source = ITEM_SOURCE.BLACKSMITHING},
    {check = JewelcraftingDB, source = ITEM_SOURCE.JEWELCRAFTING}
}

function getItemSource(itemId)
    for _, entry in ipairs(SOURCE_ORDER) do
        if entry.check[itemId] ~= nil then
            return entry.source
        end
    end
    return ITEM_SOURCE.VENDOR
end

function getItemCost(itemId)
end

