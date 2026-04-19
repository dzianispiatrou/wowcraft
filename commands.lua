SLASH_POSTITEMS1 = "/postitems"
SlashCmdList["POSTITEMS"] = function()
    PostItems()
end

SLASH_VENDORBUY1 = "/vendorbuy"
SlashCmdList["VENDORBUY"] = function()
    BuyToVendor()
end

SLASH_BUYBIDMATS1 = "/buybidmats"
SlashCmdList["BUYBIDMATS"] = function(msg)
    BuyMats(msg)
end

SLASH_BUYBIDALL1 = "/buybidall"
SlashCmdList["BUYBIDALL"] = function(msg)
    BuyAll(msg)
end

SLASH_WOWCRAFT1 = "/wowcraft"
SlashCmdList["WOWCRAFT"] = function()
    ShowWowcraftHelp()
end

SLASH_WOWCRAFTUI1 = "/wowcraftui"
SlashCmdList["WOWCRAFTUI"] = function()
    WowcraftUI_Toggle()
end

SLASH_ESTIMATE1 = "/estimate"
SlashCmdList["ESTIMATE"] = function()
    EstimateProfit()
end