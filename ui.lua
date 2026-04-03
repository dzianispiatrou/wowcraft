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
local MAT_SORTED_LIST = nil

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
            tab.isSelected = true
            tab:SetBackdropColor(0.16, 0.16, 0.18, 1)
            tab:SetBackdropBorderColor(0.65, 0.65, 0.70, 1)
            tab.label:SetTextColor(1, 1, 1)
            tab:SetPoint("BOTTOMLEFT", tab:GetParent(), "TOPLEFT", tab.baseX, -20)
        else
            tab.isSelected = false
            tab:SetBackdropColor(0.08, 0.08, 0.09, 0.95)
            tab:SetBackdropBorderColor(0.35, 0.35, 0.38, 0.9)
            tab.label:SetTextColor(0.80, 0.80, 0.85)
            tab:SetPoint("BOTTOMLEFT", tab:GetParent(), "TOPLEFT", tab.baseX, -22)
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
    b:SetSize(82, 26)
    b.baseX = x
    b:SetPoint("BOTTOMLEFT", parent, "TOPLEFT", x, y)
    b:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    b:SetBackdropColor(0.08, 0.08, 0.09, 0.95)
    b:SetBackdropBorderColor(0.35, 0.35, 0.38, 0.9)

    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER", b, "CENTER", 0, 0)
    fs:SetText(label)
    b.label = fs

    b:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.14, 1)
    end)
    b:SetScript("OnMouseUp", function(self)
        -- Selection styling is restored by TabSetSelected() on click handlers.
        if not self.isSelected then
            self:SetBackdropColor(0.08, 0.08, 0.09, 0.95)
        end
    end)
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

local function UpdateBuylistScrollBar(scroll, scrollContent, slider)
    local maxScroll = math.max(0, scrollContent:GetHeight() - scroll:GetHeight())
    slider:SetMinMaxValues(0, maxScroll)
    slider:SetValueStep(1)
    if maxScroll <= 0 then
        slider:Hide()
        slider:SetValue(0)
        scroll:SetVerticalScroll(0)
    else
        slider:Show()
        local current = scroll:GetVerticalScroll()
        if current > maxScroll then
            current = maxScroll
        end
        slider:SetValue(current)
    end
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

local function LayoutBuylistRows(scroll, scrollContent, scrollBar, scrollRightMargin)
    if not WowcraftFrame or not WowcraftBuylistPanel then
        return
    end

    local buylistPanel = WowcraftBuylistPanel
    local header = buylistPanel.headerText
    if not header then
        return
    end

    local panelW = buylistPanel:GetWidth()
    local panelH = buylistPanel:GetHeight()
    local listTopY = -34
    local scrollX = 0
    local availableW = math.max(260, panelW - scrollRightMargin)
    local availableH = math.max(90, panelH - 42)
    local rowH = 36

    scroll:ClearAllPoints()
    scroll:SetPoint("TOPLEFT", buylistPanel, "TOPLEFT", scrollX, listTopY)
    scroll:SetSize(availableW, availableH)

    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 6, 0)

    local rowWidth = availableW - 12
    for i, row in ipairs(buylistRows) do
        row:ClearAllPoints()
        row:SetSize(rowWidth, rowH - 2)
        row:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 4, -(i - 1) * rowH)
        row.nameFs:ClearAllPoints()
        row.nameFs:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.nameFs:SetPoint("RIGHT", row, "RIGHT", -120, 0)
    end

    scrollContent:SetWidth(math.max(100, availableW - 8))
    scrollContent:SetHeight(math.max(1, #buylistRows * rowH + 8))
    UpdateBuylistScrollBar(scroll, scrollContent, scrollBar)
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
    f:SetResizable(true)
    f:SetMinResize(380, 280)
    f:SetMaxResize(900, 700)
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

    local resizeBtn = CreateFrame("Button", nil, f)
    resizeBtn:SetSize(16, 16)
    resizeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 6)
    resizeBtn:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeBtn:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeBtn:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeBtn:SetScript("OnMouseDown", function()
        f:StartSizing("BOTTOMRIGHT")
    end)
    resizeBtn:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
    end)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText("Wowcraft")

    local tabBuy = CreateTabButton(f, "WowcraftFrameTab1", 1, "Buy", 12, -22)
    tabBuy:SetScript("OnClick", SelectBuyTab)

    local tabSell = CreateTabButton(f, "WowcraftFrameTab2", 2, "Sell", 94, -22)
    tabSell:SetScript("OnClick", SelectSellTab)

    local tabBuylist = CreateTabButton(f, "WowcraftFrameTab3", 3, "Buylist", 176, -22)
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
    buylistHint:SetText("Buylist (|cffffaa00MAT|r): shift+left click to link, mouse wheel or scrollbar drag to scroll.")
    buylistPanel.headerText = buylistHint

    local scrollW, scrollH = 334, 210
    local scroll, scrollContent = CreateSimpleScrollFrame(buylistPanel, scrollW, scrollH)
    scroll:SetPoint("TOPLEFT", buylistHint, "BOTTOMLEFT", 0, -6)
    scroll:SetPoint("BOTTOMLEFT", buylistPanel, "BOTTOMLEFT", 0, 0)

    local scrollBar = CreateFrame("Slider", "WowcraftBuylistScrollBar", buylistPanel)
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 8, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 8, 0)
    scrollBar:SetWidth(16)
    scrollBar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    scrollBar:SetScript("OnValueChanged", function(self, value)
        scroll:SetVerticalScroll(value)
    end)

    scroll:SetScript("OnVerticalScroll", function(self, offset)
        self:SetVerticalScroll(offset)
        scrollBar:SetValue(offset)
    end)

    local oldMouseWheel = scroll:GetScript("OnMouseWheel")
    scroll:SetScript("OnMouseWheel", function(self, delta)
        if oldMouseWheel then
            oldMouseWheel(self, delta)
        end
        scrollBar:SetValue(self:GetVerticalScroll())
    end)

    local rowH = 36
    MAT_SORTED_LIST = MAT_SORTED_LIST or BuildMatSortedList()
    local matList = MAT_SORTED_LIST
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
        row:RegisterForClicks("LeftButtonUp")
        row:SetScript("OnClick", function(self, button)
            if button ~= "LeftButton" or not IsShiftKeyDown() then
                return
            end
            local itemLink = select(2, GetItemInfo(self.itemId))
            if itemLink and ChatEdit_InsertLink then
                ChatEdit_InsertLink(itemLink)
            end
        end)

        tinsert(buylistRows, row)
        RefreshBuylistRow(row)
    end

    LayoutBuylistRows(scroll, scrollContent, scrollBar, 26)

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
        UpdateBuylistScrollBar(scroll, scrollContent, scrollBar)
    end)

    f:SetScript("OnShow", function()
        SelectBuyTab()
        UIDropDownMenu_Initialize(dropDown, WowcraftBuyDropDown_Initialize)
        UIDropDownMenu_SetText(dropDown, BUY_MODE_LABELS[WowcraftUI.buyMode])
    end)

    f:SetScript("OnSizeChanged", function()
        LayoutBuylistRows(scroll, scrollContent, scrollBar, 26)
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
