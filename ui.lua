-- Wowcraft main UI (3.3.5): tabbed frame; Buy tab wires to BuyMats / BuyAll / BuyToVendor.

WowcraftUI = WowcraftUI or {}
WowcraftUI.buyMode = "mats" -- "mats" | "all" | "vendor"

local BUY_MODE_LABELS = {
    mats = "Mats",
    all = "All (mats + crafted)",
    vendor = "Vendor (under vendor price)",
}

local tabButtons -- { Buy, Sell, Buylist }
local buylistRows = {} -- row buttons for MAT buylist

local function WowcraftBuyDropDown_Initialize()
    local function add(text, value)
        local info = UIDropDownMenu_CreateInfo()
        info.text = text
        info.value = value
        info.func = function()
            WowcraftUI.buyMode = value
            UIDropDownMenu_SetText(WowcraftBuyModeDropDown, text)
        end
        UIDropDownMenu_AddButton(info)
    end
    add(BUY_MODE_LABELS.mats, "mats")
    add(BUY_MODE_LABELS.all, "all")
    add(BUY_MODE_LABELS.vendor, "vendor")
end

local function TabSetSelected(selectedIndex)
    for i, tab in ipairs(tabButtons) do
        if i == selectedIndex then
            tab:LockHighlight()
        else
            tab:UnlockHighlight()
        end
    end
end

local function SelectBuyTab()
    WowcraftBuyPanel:Show()
    WowcraftSellPanel:Hide()
    WowcraftBuylistPanel:Hide()
    TabSetSelected(1)
end

local function SelectSellTab()
    WowcraftBuyPanel:Hide()
    WowcraftSellPanel:Show()
    WowcraftBuylistPanel:Hide()
    TabSetSelected(2)
end

local function RefreshBuylistRow(row)
    local id = row.itemId
    local price = row.matPrice
    -- 3.3.5 GetItemInfo: name, link, quality, iLvl, minLvl, type, subType, stack, equipLoc, texture, ...
    local name, _, _, _, _, _, _, _, _, tex = GetItemInfo(id)
    if tex and tex ~= "" then
        row.icon:SetTexture(tex)
    else
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    row.nameFs:SetText(name or ("Item " .. tostring(id)))
    row.priceFs:SetText(GetMoneyString(math.floor(price + 0.5)))
end

local function RefreshBuylistPanel()
    if #buylistRows == 0 then
        return
    end
    for _, row in ipairs(buylistRows) do
        RefreshBuylistRow(row)
    end
end

local function SelectBuylistTab()
    WowcraftBuyPanel:Hide()
    WowcraftSellPanel:Hide()
    WowcraftBuylistPanel:Show()
    TabSetSelected(3)
    WowcraftBuylistPanel._buylistRefreshLeft = 12
    WowcraftBuylistPanel._elapsed = 0
    RefreshBuylistPanel()
end

local function CreateTabButton(parent, globalName, id, label, x, y)
    local b = CreateFrame("Button", globalName, parent)
    b:SetID(id)
    b:SetSize(76, 26)
    b:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", x, y)
    b:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    b:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    b:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER", b, "CENTER", 0, 2)
    fs:SetText(label)
    return b
end

-- Template-free scroll (mouse wheel); works if UIPanelScrollFrameTemplate is missing.
local function CreateSimpleScrollFrame(parent, width, height)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    sf:SetSize(width, height)
    sf:EnableMouse(true)
    sf:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, sf)
    content:SetWidth(width - 8)
    sf:SetScrollChild(content)

    sf:SetScript("OnMouseWheel", function(self, delta)
        local ch = content:GetHeight()
        local sh = self:GetHeight()
        local maxScroll = math.max(0, ch - sh)
        local step = 36
        local v = self:GetVerticalScroll() - (delta * step)
        if v < 0 then
            v = 0
        elseif v > maxScroll then
            v = maxScroll
        end
        self:SetVerticalScroll(v)
    end)

    return sf, content
end

local function BuildMatSortedList()
    local list = {}
    if not MAT then
        return list
    end
    for itemId, price in pairs(MAT) do
        tinsert(list, { id = itemId, price = price })
    end
    table.sort(list, function(a, b)
        return a.id < b.id
    end)
    return list
end

local function CreateMainFrame()
    local f = CreateFrame("Frame", "WowcraftFrame", UIParent)
    f:SetSize(400, 300)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(10)
    f:Hide()

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetBackdropColor(0, 0, 0, 1)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("Wowcraft")

    local tabBuy = CreateTabButton(f, "WowcraftFrameTab1", 1, "Buy", 12, -22)
    tabBuy:SetScript("OnClick", SelectBuyTab)

    local tabSell = CreateTabButton(f, "WowcraftFrameTab2", 2, "Sell", 90, -22)
    tabSell:SetScript("OnClick", SelectSellTab)

    local tabBuylist = CreateTabButton(f, "WowcraftFrameTab3", 3, "Buylist", 168, -22)
    tabBuylist:SetScript("OnClick", SelectBuylistTab)

    tabButtons = { tabBuy, tabSell, tabBuylist }

    -- Buy panel
    local buyPanel = CreateFrame("Frame", "WowcraftBuyPanel", f)
    buyPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -52)
    buyPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)

    local lblOverbid = buyPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    lblOverbid:SetPoint("TOPLEFT", buyPanel, "TOPLEFT", 0, 0)
    lblOverbid:SetText("Overbid protection (optional, default if empty):")

    local overbidBg = CreateFrame("Frame", nil, buyPanel)
    overbidBg:SetSize(140, 28)
    overbidBg:SetPoint("TOPLEFT", lblOverbid, "BOTTOMLEFT", 0, -6)
    overbidBg:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true,
        tileSize = 5,
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    overbidBg:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    overbidBg:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

    local overbidEdit = CreateFrame("EditBox", "WowcraftOverbidEditBox", overbidBg)
    overbidEdit:SetFontObject("ChatFontNormal")
    overbidEdit:SetSize(130, 20)
    overbidEdit:SetPoint("LEFT", overbidBg, "LEFT", 6, 0)
    overbidEdit:SetAutoFocus(false)
    overbidEdit:SetMaxLetters(12)

    local lblMode = buyPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    lblMode:SetPoint("TOPLEFT", overbidBg, "BOTTOMLEFT", 0, -14)
    lblMode:SetText("Buy mode:")

    local dropDown = CreateFrame("Frame", "WowcraftBuyModeDropDown", buyPanel, "UIDropDownMenuTemplate")
    dropDown:SetPoint("TOPLEFT", lblMode, "BOTTOMLEFT", -16, -8)
    UIDropDownMenu_SetWidth(dropDown, 220)
    UIDropDownMenu_Initialize(dropDown, WowcraftBuyDropDown_Initialize)
    UIDropDownMenu_SetText(dropDown, BUY_MODE_LABELS[WowcraftUI.buyMode])

    local buyBtn = CreateFrame("Button", nil, buyPanel, "UIPanelButtonTemplate")
    buyBtn:SetSize(128, 24)
    buyBtn:SetPoint("TOPLEFT", dropDown, "BOTTOMLEFT", 16, -16)
    buyBtn:SetText("Buy")
    buyBtn:SetScript("OnClick", function()
        if not AuctionFrame or not AuctionFrame:IsShown() then
            print("|cffff8800Wowcraft:|r Open the Auction House window first.")
            return
        end
        local msg = overbidEdit:GetText()
        if msg == "" then
            msg = nil
        end
        local mode = WowcraftUI.buyMode or "mats"
        if mode == "vendor" then
            BuyToVendor()
        elseif mode == "all" then
            BuyAll(msg)
        else
            BuyMats(msg)
        end
    end)

    -- Sell panel
    local sellPanel = CreateFrame("Frame", "WowcraftSellPanel", f)
    sellPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -52)
    sellPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
    sellPanel:Hide()

    local sellHint = sellPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    sellHint:SetPoint("TOPLEFT", sellPanel, "TOPLEFT", 0, -8)
    sellHint:SetWidth(360)
    sellHint:SetJustifyH("LEFT")
    sellHint:SetText("Sell tab: use |cffffaa00/postitems|r for now. More controls can go here later.")

    -- Buylist panel (MAT from mats.lua)
    local buylistPanel = CreateFrame("Frame", "WowcraftBuylistPanel", f)
    buylistPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -52)
    buylistPanel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 16)
    buylistPanel:Hide()

    local buylistHint = buylistPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    buylistHint:SetPoint("TOPLEFT", buylistPanel, "TOPLEFT", 0, 0)
    buylistHint:SetWidth(360)
    buylistHint:SetJustifyH("LEFT")
    buylistHint:SetText("Buylist (|cffffaa00MAT|r): scroll with mouse wheel. Prices are per-unit buylist (copper).")

    local scrollW, scrollH = 352, 210
    local scroll, scrollContent = CreateSimpleScrollFrame(buylistPanel, scrollW, scrollH)
    scroll:SetPoint("TOPLEFT", buylistHint, "BOTTOMLEFT", 0, -6)

    local rowH = 36
    local matList = BuildMatSortedList()
    wipe(buylistRows)

    for i, entry in ipairs(matList) do
        local row = CreateFrame("Button", nil, scrollContent)
        row:SetSize(scrollW - 12, rowH - 2)
        row:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 4, -(i - 1) * rowH)
        row.itemId = entry.id
        row.matPrice = entry.price

        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        local ht = row:GetHighlightTexture()
        if ht then
            ht:SetAlpha(0.4)
        end

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(32, 32)
        icon:SetPoint("LEFT", row, "LEFT", 2, 0)
        row.icon = icon

        local nameFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        nameFs:SetPoint("LEFT", icon, "RIGHT", 8, 0)
        nameFs:SetPoint("RIGHT", row, "RIGHT", -120, 0)
        nameFs:SetJustifyH("LEFT")
        row.nameFs = nameFs

        local priceFs = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        priceFs:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        priceFs:SetJustifyH("RIGHT")
        priceFs:SetWidth(110)
        row.priceFs = priceFs

        row:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink("item:" .. tostring(self.itemId) .. ":0:0:0:0:0:0:0")
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        tinsert(buylistRows, row)
        RefreshBuylistRow(row)
    end

    scrollContent:SetHeight(math.max(1, #matList * rowH + 8))

    -- 3.3.5 has no item-cache callback; refresh a few times after opening tab so icons/names fill in.
    buylistPanel:SetScript("OnUpdate", function(self, elapsed)
        if not self:IsShown() then
            return
        end
        local left = self._buylistRefreshLeft or 0
        if left <= 0 then
            return
        end
        self._elapsed = (self._elapsed or 0) + elapsed
        if self._elapsed < 1 then
            return
        end
        self._elapsed = 0
        self._buylistRefreshLeft = left - 1
        RefreshBuylistPanel()
    end)

    f:SetScript("OnShow", function()
        SelectBuyTab()
        UIDropDownMenu_Initialize(dropDown, WowcraftBuyDropDown_Initialize)
        UIDropDownMenu_SetText(dropDown, BUY_MODE_LABELS[WowcraftUI.buyMode])
    end)

    return f
end

CreateMainFrame()

if UISpecialFrames then
    tinsert(UISpecialFrames, "WowcraftFrame")
end

function WowcraftUI_Toggle()
    local f = WowcraftFrame
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
    end
end
