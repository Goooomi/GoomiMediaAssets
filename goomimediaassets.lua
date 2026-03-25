-- goomimediaassets.lua - Standalone addon for registering custom media assets
-- Register textures, sounds, and fonts with LibSharedMedia-3.0 without editing Lua

GoomiMediaAssetsDB = GoomiMediaAssetsDB or {}

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- ========================
-- Constants
-- ========================
local ASSETS_PATH = "Interface\\AddOns\\GoomiMediaAssets\\assets\\"

local MEDIA_TYPES = {
    { value = "statusbar", label = "Status Bar" },
    { value = "sound",     label = "Sound" },
    { value = "font",      label = "Font" },
    { value = "background",label = "Background" },
    { value = "border",    label = "Border" },
}

local BADGE_COLORS = {
    statusbar  = { 0.2, 0.5, 0.8 },
    sound      = { 0.3, 0.7, 0.3 },
    font       = { 0.8, 0.6, 0.2 },
    background = { 0.6, 0.3, 0.7 },
    border     = { 0.2, 0.7, 0.7 },
}

-- ========================
-- Helpers
-- ========================
local function GetMediaLabel(mediaType)
    for _, mt in ipairs(MEDIA_TYPES) do
        if mt.value == mediaType then return mt.label end
    end
    return mediaType
end

local function GetBadgeColor(mediaType)
    local c = BADGE_COLORS[mediaType]
    if c then return c[1], c[2], c[3] end
    return 0.4, 0.4, 0.4
end

local function ExtractFileName(path)
    if type(path) ~= "string" then return tostring(path) end
    return path:match("([^\\/]+)$") or path
end

local function ExtractAddonName(path)
    if type(path) ~= "string" then return "WoW Default" end
    local lower = path:lower()
    local _, addonStart = lower:find("interface[/\\]addons[/\\]")
    if addonStart then
        local addonName = path:sub(addonStart + 1):match("^([^/\\]+)")
        if addonName then return addonName end
    end
    return "WoW Default"
end

-- ========================
-- Database
-- ========================
-- Pre-seeded Assets (shipped with addon, files not included)
-- Users copy the actual files into assets/ to activate them
-- ========================
local PRESEEDED_SOUNDS = {
    "AcousticGuitar", "Adds", "aggro", "AirHorn", "Applause", "Arrow_Swoosh",
    "bam", "BananaPeelSlip", "BatmanPunch", "bear_polar", "bigkiss", "BikeHorn",
    "BITE", "Blast", "Bleat", "Boss", "burp4", "CartoonVoiceBaritone",
    "CartoonWalking", "cat2", "CatMeow2", "chant2", "chant4", "ChickenAlarm",
    "chimes", "Circle", "cookie", "CowMooing", "Cross", "Diamond",
    "DontRelease", "DoubleWhoosh", "Drums", "Empowered", "ErrorBeep", "ESPARK1",
    "Fireball", "Focus", "Gasp", "GoatBleating", "heartbeat", "HeartbeatSingle",
    "hic3", "huh_1", "Hurricane", "hyena", "Idiot", "kaching",
    "KittenMeow", "Left", "moan", "Moon", "Next", "OhNo",
    "panther1", "phone", "Portal", "Protected", "PUNCH", "rainroof",
    "Release", "Right", "RingingPhone", "RoaringLion", "RobotBlip", "rocket",
    "RoosterChickenCall", "RunAway", "SharpPunch", "SheepBleat", "shipswhistle",
    "shot", "Shotgun", "Skull", "snakeattack", "sneeze", "sonar",
    "splash", "Spread", "Square", "SqueakyPig", "SqueakyToyShort", "SquishFart",
    "Stack", "Star", "Switch", "swordecho", "SynthChord", "TadaFanfare",
    "Taunt", "TempleBellHuge", "throwknife", "thunder", "Torch", "Triangle",
    "WarningSiren", "WaterDrop", "wickedmaleaugh1", "wilhelm", "wlaugh", "wolf5",
    "Xylophone", "yeehaw",
}

-- ========================
local function InitDB()
    local db = GoomiMediaAssetsDB
    if not db.assets then db.assets = {} end
end

-- Populate WA sound presets via /gma wasounds
local function PopulateWASounds()
    local db = GoomiMediaAssetsDB
    if not db.assets then db.assets = {} end

    -- Build a lookup of existing entries by key, and store index for updating
    local existing = {}
    for idx, asset in ipairs(db.assets) do
        existing[asset.mediaType .. ":" .. asset.fileName] = idx
    end

    local added = 0
    local updated = 0
    for _, name in ipairs(PRESEEDED_SOUNDS) do
        local key = "sound:" .. name .. ".ogg"
        local existIdx = existing[key]
        if existIdx then
            -- Entry exists — fix sourcePath if needed
            if db.assets[existIdx].sourcePath ~= "WeakAuras" then
                db.assets[existIdx].sourcePath = "WeakAuras"
                updated = updated + 1
            end
        else
            -- New entry
            table.insert(db.assets, {
                mediaType = "sound",
                displayName = "WA - " .. name,
                fileName = name .. ".ogg",
                sourcePath = "WeakAuras",
            })
            added = added + 1
        end
    end

    -- Re-register everything
    if LSM then
        for _, asset in ipairs(db.assets) do
            local path = ASSETS_PATH .. asset.fileName
            LSM:Register(asset.mediaType, asset.displayName, path)
        end
    end

    local parts = {}
    if added > 0 then table.insert(parts, "added " .. added) end
    if updated > 0 then table.insert(parts, "updated " .. updated) end
    if #parts > 0 then
        print("GoomiMediaAssets: " .. table.concat(parts, ", ") .. " WeakAuras sound presets. Copy the .ogg files into GoomiMediaAssets/assets/ to activate them.")
    else
        print("GoomiMediaAssets: All WeakAuras sound presets are already added.")
    end
end

-- ========================
-- LSM Registration
-- ========================
local function RegisterAllAssets()
    if not LSM then return end
    local db = GoomiMediaAssetsDB
    for _, asset in ipairs(db.assets) do
        local path = ASSETS_PATH .. asset.fileName
        LSM:Register(asset.mediaType, asset.displayName, path)
    end
end

-- ========================
-- Shared UI: Border Helper
-- ========================
local function CreateBorder(parent, thickness, r, g, b, a)
    thickness = thickness or 1
    r, g, b, a = r or 0, g or 0, b or 0, a or 1

    local borders = {}

    borders.top = parent:CreateTexture(nil, "OVERLAY")
    borders.top:SetColorTexture(r, g, b, a)
    borders.top:SetHeight(thickness)
    borders.top:SetPoint("TOPLEFT")
    borders.top:SetPoint("TOPRIGHT")

    borders.bottom = parent:CreateTexture(nil, "OVERLAY")
    borders.bottom:SetColorTexture(r, g, b, a)
    borders.bottom:SetHeight(thickness)
    borders.bottom:SetPoint("BOTTOMLEFT")
    borders.bottom:SetPoint("BOTTOMRIGHT")

    borders.left = parent:CreateTexture(nil, "OVERLAY")
    borders.left:SetColorTexture(r, g, b, a)
    borders.left:SetWidth(thickness)
    borders.left:SetPoint("TOPLEFT")
    borders.left:SetPoint("BOTTOMLEFT")

    borders.right = parent:CreateTexture(nil, "OVERLAY")
    borders.right:SetColorTexture(r, g, b, a)
    borders.right:SetWidth(thickness)
    borders.right:SetPoint("TOPRIGHT")
    borders.right:SetPoint("BOTTOMRIGHT")

    return borders
end

local function SetBorderColor(borders, r, g, b, a)
    if not borders then return end
    borders.top:SetColorTexture(r, g, b, a)
    borders.bottom:SetColorTexture(r, g, b, a)
    borders.left:SetColorTexture(r, g, b, a)
    borders.right:SetColorTexture(r, g, b, a)
end

-- ========================
-- Styled Button
-- ========================
local function CreateStyledButton(parent, width, height, text)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, height)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.14, 0.14, 0.14, 1)

    btn.borders = CreateBorder(btn, 1, 0.25, 0.25, 0.25, 1)

    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("CENTER", 0, 0)
    btn.label:SetText(text or "")
    btn.label:SetTextColor(0.9, 0.9, 0.9, 1)

    btn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.22, 0.22, 0.22, 1)
        SetBorderColor(self.borders, 0.35, 0.35, 0.35, 1)
        self.label:SetTextColor(1, 1, 1, 1)
    end)

    btn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.14, 0.14, 0.14, 1)
        SetBorderColor(self.borders, 0.25, 0.25, 0.25, 1)
        self.label:SetTextColor(0.9, 0.9, 0.9, 1)
    end)

    btn:SetScript("OnMouseDown", function(self)
        self.bg:SetColorTexture(0.08, 0.08, 0.08, 1)
    end)

    btn:SetScript("OnMouseUp", function(self)
        if self:IsMouseOver() then
            self.bg:SetColorTexture(0.22, 0.22, 0.22, 1)
        else
            self.bg:SetColorTexture(0.14, 0.14, 0.14, 1)
        end
    end)

    function btn:SetText(t)
        self.label:SetText(t)
    end

    function btn:GetText()
        return self.label:GetText()
    end

    return btn
end

-- ========================
-- Styled EditBox
-- ========================
local function CreateStyledEditBox(parent, width, height)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(width, height)

    container.bg = container:CreateTexture(nil, "BACKGROUND")
    container.bg:SetAllPoints()
    container.bg:SetColorTexture(0.06, 0.06, 0.06, 1)

    container.borders = CreateBorder(container, 1, 0.22, 0.22, 0.22, 1)

    local editBox = CreateFrame("EditBox", nil, container)
    editBox:SetPoint("TOPLEFT", 6, -2)
    editBox:SetPoint("BOTTOMRIGHT", -6, 2)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetAutoFocus(false)
    editBox:SetTextColor(0.9, 0.9, 0.9, 1)

    editBox:SetScript("OnEditFocusGained", function()
        SetBorderColor(container.borders, 0.3, 0.5, 0.7, 1)
    end)

    editBox:SetScript("OnEditFocusLost", function()
        SetBorderColor(container.borders, 0.22, 0.22, 0.22, 1)
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    -- Expose the editBox but anchor via the container
    editBox.container = container
    editBox.SetPoint = function(self, ...)
        container:SetPoint(...)
    end

    -- Forward container methods
    function editBox:SetWidth(w)
        container:SetSize(w, container:GetHeight())
    end

    return editBox
end

-- ========================
-- Styled Dropdown
-- ========================
local activeDropdown = nil -- track which dropdown menu is open

local function CloseActiveDropdown()
    if activeDropdown then
        activeDropdown:Hide()
        activeDropdown = nil
    end
end

local function CreateStyledDropdown(parent, width)
    local dropdown = {}

    -- The visible button
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, 24)

    btn.bg = btn:CreateTexture(nil, "BACKGROUND")
    btn.bg:SetAllPoints()
    btn.bg:SetColorTexture(0.1, 0.1, 0.1, 1)

    btn.borders = CreateBorder(btn, 1, 0.22, 0.22, 0.22, 1)

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btn.text:SetPoint("LEFT", 8, 0)
    btn.text:SetPoint("RIGHT", -18, 0)
    btn.text:SetJustifyH("LEFT")
    btn.text:SetTextColor(0.9, 0.9, 0.9, 1)

    -- Arrow indicator
    btn.arrow = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.arrow:SetPoint("RIGHT", -6, 0)
    btn.arrow:SetText("v")
    btn.arrow:SetTextColor(0.5, 0.5, 0.5, 1)

    btn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.15, 0.15, 0.15, 1)
        SetBorderColor(self.borders, 0.3, 0.3, 0.3, 1)
    end)

    btn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.1, 0.1, 0.1, 1)
        SetBorderColor(self.borders, 0.22, 0.22, 0.22, 1)
    end)

    -- The dropdown menu frame
    local menu = CreateFrame("Frame", nil, btn)
    menu:SetWidth(width)
    menu:SetFrameStrata("DIALOG")
    menu:SetFrameLevel(100)
    menu:Hide()

    menu.bg = menu:CreateTexture(nil, "BACKGROUND")
    menu.bg:SetAllPoints()
    menu.bg:SetColorTexture(0.08, 0.08, 0.08, 0.98)

    menu.borders = CreateBorder(menu, 1, 0.25, 0.25, 0.25, 1)

    -- Scroll support for long lists
    local menuScroll = CreateFrame("ScrollFrame", nil, menu)
    menuScroll:SetPoint("TOPLEFT", 1, -1)
    menuScroll:SetPoint("BOTTOMRIGHT", -1, 1)

    local menuChild = CreateFrame("Frame", nil, menuScroll)
    menuChild:SetWidth(width - 2)
    menuScroll:SetScrollChild(menuChild)

    -- Enable mouse wheel scrolling
    menu:EnableMouseWheel(true)
    menu:SetScript("OnMouseWheel", function(self, delta)
        local current = menuScroll:GetVerticalScroll()
        local maxScroll = menuChild:GetHeight() - menuScroll:GetHeight()
        if maxScroll < 0 then maxScroll = 0 end
        local newScroll = current - (delta * 20)
        if newScroll < 0 then newScroll = 0 end
        if newScroll > maxScroll then newScroll = maxScroll end
        menuScroll:SetVerticalScroll(newScroll)
    end)

    local ITEM_HEIGHT = 22
    local MAX_VISIBLE = 12
    local options = {}
    local selectedValue = nil
    local onSelectCallback = nil

    local function RefreshMenu()
        -- Clear existing items
        local children = { menuChild:GetChildren() }
        for _, child in ipairs(children) do
            child:Hide()
            child:ClearAllPoints()
            child:SetParent(nil)
        end

        local itemCount = #options
        local visibleCount = math.min(itemCount, MAX_VISIBLE)
        local menuHeight = visibleCount * ITEM_HEIGHT + 2
        menu:SetHeight(menuHeight)
        menuChild:SetHeight(math.max(itemCount * ITEM_HEIGHT, 1))

        for i, opt in ipairs(options) do
            local item = CreateFrame("Button", nil, menuChild)
            item:SetSize(width - 2, ITEM_HEIGHT)
            item:SetPoint("TOPLEFT", 0, -((i - 1) * ITEM_HEIGHT))

            item.bg = item:CreateTexture(nil, "BACKGROUND")
            item.bg:SetAllPoints()

            local isSelected = (opt.value == selectedValue)
            if isSelected then
                item.bg:SetColorTexture(0.2, 0.4, 0.6, 0.4)
            else
                item.bg:SetColorTexture(0, 0, 0, 0)
            end

            item.text = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            item.text:SetPoint("LEFT", 8, 0)
            item.text:SetText(opt.label)
            item.text:SetTextColor(isSelected and 1 or 0.85, isSelected and 1 or 0.85, isSelected and 1 or 0.85, 1)

            item:SetScript("OnEnter", function(self)
                if opt.value ~= selectedValue then
                    self.bg:SetColorTexture(0.18, 0.18, 0.18, 1)
                end
                self.text:SetTextColor(1, 1, 1, 1)
            end)

            item:SetScript("OnLeave", function(self)
                if opt.value == selectedValue then
                    self.bg:SetColorTexture(0.2, 0.4, 0.6, 0.4)
                else
                    self.bg:SetColorTexture(0, 0, 0, 0)
                end
                self.text:SetTextColor(opt.value == selectedValue and 1 or 0.85, opt.value == selectedValue and 1 or 0.85, opt.value == selectedValue and 1 or 0.85, 1)
            end)

            item:SetScript("OnClick", function()
                selectedValue = opt.value
                btn.text:SetText(opt.label)
                menu:Hide()
                activeDropdown = nil
                if onSelectCallback then
                    onSelectCallback(opt.value, opt.label)
                end
            end)
        end
    end

    -- Toggle menu on button click
    btn:SetScript("OnClick", function(self)
        if menu:IsShown() then
            menu:Hide()
            activeDropdown = nil
        else
            CloseActiveDropdown()
            menu:ClearAllPoints()
            menu:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
            RefreshMenu()
            menu:Show()
            activeDropdown = menu
        end
    end)

    -- Close menu when clicking elsewhere
    menu:SetScript("OnHide", function()
        if activeDropdown == menu then
            activeDropdown = nil
        end
    end)

    -- Public API
    dropdown.button = btn

    function dropdown:SetPoint(...)
        btn:SetPoint(...)
    end

    function dropdown:SetText(text)
        btn.text:SetText(text)
    end

    function dropdown:GetValue()
        return selectedValue
    end

    function dropdown:SetValue(value)
        selectedValue = value
        for _, opt in ipairs(options) do
            if opt.value == value then
                btn.text:SetText(opt.label)
                break
            end
        end
    end

    function dropdown:SetOptions(newOptions)
        options = newOptions
        if menu:IsShown() then
            RefreshMenu()
        end
    end

    function dropdown:SetCallback(fn)
        onSelectCallback = fn
    end

    function dropdown:Close()
        menu:Hide()
    end

    return dropdown
end

-- Close any open dropdown when clicking the world
local dropdownCloser = CreateFrame("Frame")
dropdownCloser:RegisterEvent("GLOBAL_MOUSE_DOWN")
dropdownCloser:SetScript("OnEvent", function()
    if activeDropdown and activeDropdown:IsShown() then
        -- Check if mouse is over the menu or its parent button
        if not activeDropdown:IsMouseOver() and not activeDropdown:GetParent():IsMouseOver() then
            activeDropdown:Hide()
            activeDropdown = nil
        end
    end
end)

-- ========================
-- Styled Scroll Bar
-- ========================
local function StyleScrollBar(scrollFrameName)
    local scrollBar = _G[scrollFrameName .. "ScrollBar"]
    if not scrollBar then return end

    -- Hide Blizzard arrow buttons
    local upBtn = _G[scrollFrameName .. "ScrollBarScrollUpButton"]
    local downBtn = _G[scrollFrameName .. "ScrollBarScrollDownButton"]
    if upBtn then upBtn:Hide(); upBtn:SetAlpha(0); upBtn:SetSize(1, 1) end
    if downBtn then downBtn:Hide(); downBtn:SetAlpha(0); downBtn:SetSize(1, 1) end

    -- Hide the default track background
    for _, region in pairs({ scrollBar:GetRegions() }) do
        local objType = region:GetObjectType()
        if objType == "Texture" and region ~= scrollBar:GetThumbTexture() then
            region:SetAlpha(0)
        end
    end

    -- Style the scroll bar itself
    scrollBar:SetWidth(14)

    -- Add a subtle track background
    local track = scrollBar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0.08, 0.08, 0.08, 0.6)

    -- Style the thumb
    local thumb = scrollBar:GetThumbTexture()
    thumb:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    thumb:SetSize(14, 40)

    -- Adjust scroll bar position — anchor to the parent area (listArea/findArea)
    -- so it sits outside the scroll content, not overlapping rows
    local parentArea = scrollBar:GetParent():GetParent()
    scrollBar:ClearAllPoints()
    scrollBar:SetPoint("TOPRIGHT", parentArea, "TOPRIGHT", -8, -6)
    scrollBar:SetPoint("BOTTOMRIGHT", parentArea, "BOTTOMRIGHT", -8, 6)
end

-- ========================
-- Shared UI: ClearChildren
-- ========================
local function ClearChildren(frame)
    local children = { frame:GetChildren() }
    for i = 1, #children do
        children[i]:Hide()
        children[i]:ClearAllPoints()
        children[i]:SetParent(nil)
    end
    local regions = { frame:GetRegions() }
    for i = 1, #regions do
        if regions[i]:GetObjectType() == "FontString" then
            regions[i]:Hide()
            regions[i]:SetText("")
        end
    end
end

-- ========================
-- Settings Window
-- ========================
local settingsFrame = nil
local settingsBuilt = false

local function CreateSettingsFrame()
    if settingsFrame then return settingsFrame end

    local frame = CreateFrame("Frame", "GoomiMediaAssetsSettingsFrame", UIParent)
    frame:SetSize(780, 650)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH")
    frame:Hide()

    table.insert(UISpecialFrames, "GoomiMediaAssetsSettingsFrame")

    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)

    CreateBorder(frame, 2, 0.2, 0.2, 0.2, 1)

    -- Title bar
    frame.titleBar = CreateFrame("Frame", nil, frame)
    frame.titleBar:SetHeight(40)
    frame.titleBar:SetPoint("TOPLEFT", 0, 0)
    frame.titleBar:SetPoint("TOPRIGHT", 0, 0)

    frame.titleBar.bg = frame.titleBar:CreateTexture(nil, "BACKGROUND")
    frame.titleBar.bg:SetAllPoints()
    frame.titleBar.bg:SetColorTexture(0.1, 0.1, 0.1, 1)

    frame.titleBar.border = frame.titleBar:CreateTexture(nil, "OVERLAY")
    frame.titleBar.border:SetColorTexture(0.3, 0.3, 0.3, 1)
    frame.titleBar.border:SetHeight(1)
    frame.titleBar.border:SetPoint("BOTTOMLEFT")
    frame.titleBar.border:SetPoint("BOTTOMRIGHT")

    frame.title = frame.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("LEFT", 15, 0)
    frame.title:SetText("Goomi |cFF3AC2D6M|redia |cFFEE2D40A|rssets")
    frame.title:SetTextColor(1, 1, 1, 1)

    -- Close button (styled)
    frame.closeBtn = CreateFrame("Button", nil, frame.titleBar)
    frame.closeBtn:SetSize(30, 30)
    frame.closeBtn:SetPoint("RIGHT", -5, 0)

    frame.closeBtn.bg = frame.closeBtn:CreateTexture(nil, "BACKGROUND")
    frame.closeBtn.bg:SetAllPoints()
    frame.closeBtn.bg:SetColorTexture(0.15, 0.15, 0.15, 1)

    frame.closeBtn.text = frame.closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.closeBtn.text:SetPoint("CENTER")
    frame.closeBtn.text:SetText("\195\151")
    frame.closeBtn.text:SetTextColor(0.8, 0.8, 0.8, 1)

    frame.closeBtn:SetScript("OnEnter", function(self)
        self.bg:SetColorTexture(0.7, 0.2, 0.2, 1)
        self.text:SetTextColor(1, 1, 1, 1)
    end)

    frame.closeBtn:SetScript("OnLeave", function(self)
        self.bg:SetColorTexture(0.15, 0.15, 0.15, 1)
        self.text:SetTextColor(0.8, 0.8, 0.8, 1)
    end)

    frame.closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    -- Content area
    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetPoint("TOPLEFT", 20, -55)
    frame.content:SetPoint("BOTTOMRIGHT", -20, 20)

    settingsFrame = frame
    return frame
end

-- ========================
-- Build Settings Content
-- ========================
local function BuildSettingsContent(parentFrame)
    if settingsBuilt then return end
    settingsBuilt = true

    local db = GoomiMediaAssetsDB

    if not LSM then
        local warn = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        warn:SetPoint("TOPLEFT", 0, 0)
        warn:SetWidth(550)
        warn:SetJustifyH("LEFT")
        warn:SetText("LibSharedMedia-3.0 was not found. This addon requires LSM to function. Install it or an addon that bundles it (e.g. WeakAuras, ElvUI).")
        warn:SetTextColor(1, 0.3, 0.3, 1)
        return
    end

    -- ==============================
    -- Tab System
    -- ==============================
    local tabs, tabButtons = {}, {}

    local function ShowTab(idx)
        for i, t in ipairs(tabs) do t:SetShown(i == idx) end
        for i, b in ipairs(tabButtons) do
            local on = (i == idx)
            b.bg:SetColorTexture(
                on and 0.2 or 0.1,
                on and 0.4 or 0.1,
                on and 0.6 or 0.1,
                on and 0.6 or 0.5
            )
            b.label:SetTextColor(on and 1 or 0.6, on and 1 or 0.6, on and 1 or 0.6, 1)
        end
    end

    local tabNames = { "My Assets", "Find Assets", "Guide" }
    for i, name in ipairs(tabNames) do
        local btn = CreateFrame("Button", nil, parentFrame)
        btn:SetSize(90, 30)
        btn:SetPoint("TOPLEFT", (i - 1) * 95, 0)

        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()
        btn.bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)

        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.label:SetPoint("CENTER")
        btn.label:SetText(name)

        btn:SetScript("OnClick", function() ShowTab(i) end)
        tabButtons[i] = btn
    end

    for i = 1, 3 do
        local f = CreateFrame("Frame", nil, parentFrame)
        f:SetPoint("TOPLEFT", 0, -35)
        f:SetPoint("BOTTOMRIGHT", 0, 0)
        f:Hide()
        tabs[i] = f
    end

    -- ==============================
    -- Forward declarations
    -- ==============================
    local RefreshMyAssets
    local formMediaType
    local formDisplayName   -- EditBox
    local formFileName      -- EditBox
    local formSaveBtn
    local formCancelBtn
    local formTitle
    local typeDropdown      -- styled dropdown
    local editingIndex = nil
    local pendingSourcePath = nil

    -- ==============================
    -- Tab 1: My Assets
    -- ==============================
    local tab1 = tabs[1]

    local tab1Desc = tab1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tab1Desc:SetPoint("TOPLEFT", 0, 0)
    tab1Desc:SetWidth(700)
    tab1Desc:SetJustifyH("LEFT")
    tab1Desc:SetText("Register your own files with LibSharedMedia. Drop files into the addon's assets/ folder, then add them here.")
    tab1Desc:SetTextColor(0.5, 0.5, 0.5, 1)

    -- Filter bar
    local tab1FilterBar = CreateFrame("Frame", nil, tab1)
    tab1FilterBar:SetHeight(36)
    tab1FilterBar:SetPoint("TOPLEFT", 0, -20)
    tab1FilterBar:SetPoint("TOPRIGHT", 0, -20)

    tab1FilterBar.bg = tab1FilterBar:CreateTexture(nil, "BACKGROUND")
    tab1FilterBar.bg:SetAllPoints()
    tab1FilterBar.bg:SetColorTexture(0.08, 0.08, 0.08, 0.5)
    CreateBorder(tab1FilterBar, 1, 0.2, 0.2, 0.2, 0.5)

    -- Type filter toggles
    local tab1TypeFilters = {}
    local tab1TypeToggleButtons = {}

    for _, mt in ipairs(MEDIA_TYPES) do
        tab1TypeFilters[mt.value] = true
    end

    local tab1FiltersLabel = tab1FilterBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tab1FiltersLabel:SetPoint("LEFT", 8, 0)
    tab1FiltersLabel:SetText("Filters:")
    tab1FiltersLabel:SetTextColor(0.5, 0.5, 0.5, 1)

    local tab1ToggleX = 50
    for i, mt in ipairs(MEDIA_TYPES) do
        local btn = CreateFrame("Button", nil, tab1FilterBar)
        local br, bg, bb = GetBadgeColor(mt.value)
        local labelWidth = mt.label:len() * 6 + 16

        btn:SetSize(labelWidth, 22)
        btn:SetPoint("LEFT", tab1ToggleX, 0)

        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()

        btn.borders = CreateBorder(btn, 1, br, bg, bb, 0.6)

        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.label:SetPoint("CENTER")
        btn.label:SetText(mt.label)

        btn.mediaType = mt.value

        local function UpdateToggleVisual()
            if tab1TypeFilters[mt.value] then
                btn.bg:SetColorTexture(br, bg, bb, 0.4)
                btn.label:SetTextColor(br + 0.3, bg + 0.3, bb + 0.3, 1)
                SetBorderColor(btn.borders, br, bg, bb, 0.6)
            else
                btn.bg:SetColorTexture(0.12, 0.12, 0.12, 0.5)
                btn.label:SetTextColor(0.4, 0.4, 0.4, 0.7)
                SetBorderColor(btn.borders, 0.2, 0.2, 0.2, 0.3)
            end
        end

        btn:SetScript("OnClick", function()
            tab1TypeFilters[mt.value] = not tab1TypeFilters[mt.value]
            UpdateToggleVisual()
            RefreshMyAssets()
        end)

        UpdateToggleVisual()

        tab1TypeToggleButtons[mt.value] = btn
        tab1ToggleX = tab1ToggleX + labelWidth + 4
    end

    -- Source filter dropdown
    local tab1SourceLabel = tab1FilterBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tab1SourceLabel:SetPoint("RIGHT", tab1FilterBar, "RIGHT", -170, 0)
    tab1SourceLabel:SetText("Source:")
    tab1SourceLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local tab1FilterSource = "All"
    local tab1SourceDropdown = CreateStyledDropdown(tab1FilterBar, 140)
    tab1SourceDropdown:SetPoint("LEFT", tab1SourceLabel, "RIGHT", 8, 0)

    -- Rebuild source dropdown options from current assets
    local function RefreshTab1SourceDropdown()
        local sourceSet = {}
        local sources = {}
        for _, asset in ipairs(db.assets) do
            local src = asset.sourcePath or "User Added"
            if src:find("[/\\]") then
                src = ExtractAddonName(src)
            end
            if not sourceSet[src] then
                sourceSet[src] = true
                table.insert(sources, src)
            end
        end
        table.sort(sources)

        local opts = { { value = "All", label = "All" } }
        for _, src in ipairs(sources) do
            table.insert(opts, { value = src, label = src })
        end

        tab1SourceDropdown:SetOptions(opts)
        tab1SourceDropdown:SetValue(tab1FilterSource)
    end

    tab1SourceDropdown:SetCallback(function(value)
        tab1FilterSource = value
        RefreshMyAssets()
    end)

    -- Search bar
    local tab1SearchBar = CreateFrame("Frame", nil, tab1)
    tab1SearchBar:SetHeight(30)
    tab1SearchBar:SetPoint("TOPLEFT", 0, -58)
    tab1SearchBar:SetPoint("TOPRIGHT", 0, -58)

    tab1SearchBar.bg = tab1SearchBar:CreateTexture(nil, "BACKGROUND")
    tab1SearchBar.bg:SetAllPoints()
    tab1SearchBar.bg:SetColorTexture(0.08, 0.08, 0.08, 0.5)
    CreateBorder(tab1SearchBar, 1, 0.2, 0.2, 0.2, 0.5)

    local tab1SearchLabel = tab1SearchBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tab1SearchLabel:SetPoint("LEFT", 8, 0)
    tab1SearchLabel:SetText("Search:")
    tab1SearchLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local tab1SearchBox = CreateStyledEditBox(tab1SearchBar, 250, 22)
    tab1SearchBox:SetPoint("LEFT", tab1SearchLabel, "RIGHT", 8, 0)

    local tab1SearchHint = tab1SearchBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tab1SearchHint:SetPoint("LEFT", tab1SearchBox.container, "RIGHT", 10, 0)
    tab1SearchHint:SetText("Search by display name")
    tab1SearchHint:SetTextColor(0.4, 0.4, 0.4, 1)

    tab1SearchBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            RefreshMyAssets()
        end
    end)

    tab1SearchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    tab1SearchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        RefreshMyAssets()
    end)

    -- Column headers
    local tab1HeaderRow = CreateFrame("Frame", nil, tab1)
    tab1HeaderRow:SetHeight(22)
    tab1HeaderRow:SetPoint("TOPLEFT", 0, -90)
    tab1HeaderRow:SetPoint("TOPRIGHT", 0, -90)

    tab1HeaderRow.bg = tab1HeaderRow:CreateTexture(nil, "BACKGROUND")
    tab1HeaderRow.bg:SetAllPoints()
    tab1HeaderRow.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    local tab1ColType = tab1HeaderRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tab1ColType:SetPoint("LEFT", 8, 0)
    tab1ColType:SetText("TYPE")
    tab1ColType:SetTextColor(0.6, 0.6, 0.6, 1)

    local tab1ColName = tab1HeaderRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tab1ColName:SetPoint("LEFT", 85, 0)
    tab1ColName:SetText("DISPLAY NAME")
    tab1ColName:SetTextColor(0.6, 0.6, 0.6, 1)

    local tab1ColFile = tab1HeaderRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tab1ColFile:SetPoint("LEFT", 280, 0)
    tab1ColFile:SetText("FILE NAME")
    tab1ColFile:SetTextColor(0.6, 0.6, 0.6, 1)

    local tab1ColSource = tab1HeaderRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tab1ColSource:SetPoint("LEFT", 470, 0)
    tab1ColSource:SetText("SOURCE")
    tab1ColSource:SetTextColor(0.6, 0.6, 0.6, 1)

    -- Scroll area
    local listArea = CreateFrame("Frame", nil, tab1)
    listArea:SetPoint("TOPLEFT", 0, -112)
    listArea:SetPoint("RIGHT", 0, 0)
    listArea:SetPoint("BOTTOM", 0, 80)

    listArea.bg = listArea:CreateTexture(nil, "BACKGROUND")
    listArea.bg:SetAllPoints()
    listArea.bg:SetColorTexture(0.08, 0.08, 0.08, 0.5)
    CreateBorder(listArea, 1, 0.2, 0.2, 0.2, 0.5)

    local listScroll = CreateFrame("ScrollFrame", "GoomiMediaAssetsListScroll", listArea, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", 5, -5)
    listScroll:SetPoint("BOTTOMRIGHT", -20, 5)

    StyleScrollBar("GoomiMediaAssetsListScroll")

    local listChild = CreateFrame("Frame", nil, listScroll)
    listChild:SetSize(1, 1)
    listScroll:SetScrollChild(listChild)

    local emptyMsg = listArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyMsg:SetPoint("CENTER")
    emptyMsg:SetText("No assets registered yet. Use the form below to add one.")
    emptyMsg:SetTextColor(0.4, 0.4, 0.4, 1)

    -- Build asset list rows
    RefreshMyAssets = function()
        ClearChildren(listChild)

        -- Refresh source dropdown options
        RefreshTab1SourceDropdown()

        local assets = db.assets

        if #assets == 0 then
            emptyMsg:SetText("No assets registered yet. Use the form below to add one.")
            emptyMsg:Show()
            listChild:SetHeight(1)
            return
        end

        -- Filter assets
        local tab1SearchText = strtrim(tab1SearchBox:GetText()):lower()
        local isSearching = (tab1SearchText ~= "")

        local filtered = {}
        for idx, asset in ipairs(assets) do
            -- Type filter
            if tab1TypeFilters[asset.mediaType] then
                -- Source filter
                local assetSource = asset.sourcePath or "User Added"
                if assetSource:find("[/\\]") then
                    assetSource = ExtractAddonName(assetSource)
                end

                if tab1FilterSource == "All" or assetSource == tab1FilterSource then
                    -- Search filter
                    if not isSearching or asset.displayName:lower():find(tab1SearchText, 1, true) then
                        table.insert(filtered, { asset = asset, idx = idx })
                    end
                end
            end
        end

        if #filtered == 0 then
            emptyMsg:SetText("No assets match the current filters.")
            emptyMsg:Show()
            listChild:SetHeight(1)
            return
        end
        emptyMsg:Hide()

        local ROW_HEIGHT = 34
        local yOff = 0

        for rowNum, entry in ipairs(filtered) do
            local asset = entry.asset
            local idx = entry.idx

            local row = CreateFrame("Frame", nil, listChild)
            row:SetSize(listChild:GetParent():GetWidth() - 10, ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 0, -yOff)

            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            row.bg:SetColorTexture(0.1, 0.1, 0.1, (rowNum % 2 == 0) and 0.3 or 0.5)

            -- Type badge
            local badge = CreateFrame("Frame", nil, row)
            badge:SetSize(65, 20)
            badge:SetPoint("LEFT", 6, 0)

            local br, bg, bb = GetBadgeColor(asset.mediaType)
            badge.bg = badge:CreateTexture(nil, "ARTWORK")
            badge.bg:SetAllPoints()
            badge.bg:SetColorTexture(br, bg, bb, 0.3)
            CreateBorder(badge, 1, br, bg, bb, 0.6)

            local badgeText = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            badgeText:SetPoint("CENTER")
            badgeText:SetText(GetMediaLabel(asset.mediaType))
            badgeText:SetTextColor(br + 0.3, bg + 0.3, bb + 0.3, 1)

            -- Display name
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("LEFT", badge, "RIGHT", 10, 0)
            nameText:SetWidth(175)
            nameText:SetJustifyH("LEFT")
            nameText:SetText(asset.displayName)
            nameText:SetTextColor(1, 1, 1, 1)

            -- Filename
            local fileText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fileText:SetPoint("LEFT", 280, 0)
            fileText:SetWidth(180)
            fileText:SetJustifyH("LEFT")
            fileText:SetText(asset.fileName)
            fileText:SetTextColor(0.6, 0.6, 0.6, 1)

            -- Source
            local sourcePath = asset.sourcePath
            local sourceDisplayName
            if not sourcePath then
                sourceDisplayName = "User Added"
            elseif sourcePath:find("[/\\]") then
                sourceDisplayName = ExtractAddonName(sourcePath)
            else
                sourceDisplayName = sourcePath
            end

            local sourceText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            sourceText:SetPoint("LEFT", 470, 0)
            sourceText:SetWidth(80)
            sourceText:SetJustifyH("LEFT")
            sourceText:SetText(sourceDisplayName)
            sourceText:SetTextColor(0.5, 0.5, 0.5, 1)

            -- Edit button
            local editBtn = CreateStyledButton(row, 45, 22, "Edit")
            editBtn:SetPoint("RIGHT", row, "RIGHT", -55, 0)

            editBtn:SetScript("OnClick", function()
                editingIndex = idx
                pendingSourcePath = asset.sourcePath
                formTitle:SetText("EDIT ASSET")

                formMediaType = asset.mediaType
                typeDropdown:SetValue(asset.mediaType)

                formDisplayName:SetText(asset.displayName)
                formFileName:SetText(asset.fileName)
                formCancelBtn:Show()
            end)

            -- Delete button
            local delBtn = CreateStyledButton(row, 50, 22, "Delete")
            delBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)

            delBtn:SetScript("OnClick", function()
                table.remove(db.assets, idx)
                if editingIndex == idx then
                    editingIndex = nil
                    pendingSourcePath = nil
                    formTitle:SetText("ADD NEW ASSET")
                    formDisplayName:SetText("")
                    formFileName:SetText("")
                    formCancelBtn:Hide()
                end
                RefreshMyAssets()
            end)

            yOff = yOff + ROW_HEIGHT + 2
        end

        listChild:SetHeight(math.max(yOff, 1))
    end

    -- ==============================
    -- Tab 1: Add/Edit Form (condensed)
    -- ==============================
    local formArea = CreateFrame("Frame", nil, tab1)
    formArea:SetHeight(70)
    formArea:SetPoint("BOTTOMLEFT", 0, 0)
    formArea:SetPoint("BOTTOMRIGHT", 0, 0)

    formArea.bg = formArea:CreateTexture(nil, "BACKGROUND")
    formArea.bg:SetAllPoints()
    formArea.bg:SetColorTexture(0.08, 0.08, 0.08, 0.5)
    CreateBorder(formArea, 1, 0.2, 0.2, 0.2, 0.5)

    formTitle = formArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    formTitle:SetPoint("TOPLEFT", 10, -5)
    formTitle:SetText("ADD NEW ASSET")
    formTitle:SetTextColor(1, 1, 1, 1)

    -- Hint at bottom
    local formHint = formArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    formHint:SetPoint("BOTTOMLEFT", 10, 5)
    formHint:SetText("File must exist in GoomiMediaAssets/assets/")
    formHint:SetTextColor(0.4, 0.4, 0.4, 1)

    -- Single input row anchored between title and hint
    local typeLabel = formArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    typeLabel:SetPoint("LEFT", 10, 2)
    typeLabel:SetText("Type:")
    typeLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    formMediaType = "statusbar"

    local typeOptions = {}
    for _, mt in ipairs(MEDIA_TYPES) do
        table.insert(typeOptions, { value = mt.value, label = mt.label })
    end

    typeDropdown = CreateStyledDropdown(formArea, 84)
    typeDropdown:SetPoint("LEFT", typeLabel, "RIGHT", 5, 0)
    typeDropdown:SetOptions(typeOptions)
    typeDropdown:SetValue("statusbar")
    typeDropdown:SetCallback(function(value, label)
        formMediaType = value
    end)

    local nameLabel = formArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("LEFT", typeDropdown.button, "RIGHT", 10, 0)
    nameLabel:SetText("Name:")
    nameLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    formDisplayName = CreateStyledEditBox(formArea, 160, 22)
    formDisplayName:SetPoint("LEFT", nameLabel, "RIGHT", 5, 0)

    local fileLabel = formArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fileLabel:SetPoint("LEFT", formDisplayName.container, "RIGHT", 10, 0)
    fileLabel:SetText("File:")
    fileLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    formFileName = CreateStyledEditBox(formArea, 150, 22)
    formFileName:SetPoint("LEFT", fileLabel, "RIGHT", 5, 0)

    formSaveBtn = CreateStyledButton(formArea, 60, 22, "Save")
    formSaveBtn:SetPoint("LEFT", formFileName.container, "RIGHT", 8, 0)

    formCancelBtn = CreateStyledButton(formArea, 60, 22, "Cancel")
    formCancelBtn:SetPoint("LEFT", formSaveBtn, "RIGHT", 4, 0)
    formCancelBtn:Hide()

    formSaveBtn:SetScript("OnClick", function()
        local dName = strtrim(formDisplayName:GetText())
        local fName = strtrim(formFileName:GetText())

        if dName == "" or fName == "" then
            print("GoomiMediaAssets: Display name and file name are required.")
            return
        end

        local entry = {
            mediaType = formMediaType,
            displayName = dName,
            fileName = fName,
            sourcePath = pendingSourcePath,
        }

        if editingIndex then
            db.assets[editingIndex] = entry
        else
            table.insert(db.assets, entry)
        end

        if LSM then
            local path = ASSETS_PATH .. entry.fileName
            LSM:Register(entry.mediaType, entry.displayName, path)
        end

        editingIndex = nil
        pendingSourcePath = nil
        formTitle:SetText("ADD NEW ASSET")
        formDisplayName:SetText("")
        formFileName:SetText("")
        formCancelBtn:Hide()

        RefreshMyAssets()
    end)

    formCancelBtn:SetScript("OnClick", function()
        editingIndex = nil
        pendingSourcePath = nil
        formTitle:SetText("ADD NEW ASSET")
        formDisplayName:SetText("")
        formFileName:SetText("")
        formCancelBtn:Hide()
    end)

    RefreshMyAssets()

    -- ==============================
    -- Tab 2: Find Assets
    -- ==============================
    local tab2 = tabs[2]

    local tab2Desc = tab2:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tab2Desc:SetPoint("TOPLEFT", 0, 0)
    tab2Desc:SetWidth(700)
    tab2Desc:SetJustifyH("LEFT")
    tab2Desc:SetText("Browse assets registered by other addons. Use Add to pre-fill the form on My Assets.")
    tab2Desc:SetTextColor(0.5, 0.5, 0.5, 1)

    -- Filter bar
    local filterBar = CreateFrame("Frame", nil, tab2)
    filterBar:SetHeight(36)
    filterBar:SetPoint("TOPLEFT", 0, -20)
    filterBar:SetPoint("TOPRIGHT", 0, -20)

    filterBar.bg = filterBar:CreateTexture(nil, "BACKGROUND")
    filterBar.bg:SetAllPoints()
    filterBar.bg:SetColorTexture(0.08, 0.08, 0.08, 0.5)
    CreateBorder(filterBar, 1, 0.2, 0.2, 0.2, 0.5)

    -- Type filter toggles
    local typeFilters = {}
    local typeToggleButtons = {}

    for _, mt in ipairs(MEDIA_TYPES) do
        typeFilters[mt.value] = true
    end

    local RefreshFindAssets

    local findFiltersLabel = filterBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    findFiltersLabel:SetPoint("LEFT", 8, 0)
    findFiltersLabel:SetText("Filters:")
    findFiltersLabel:SetTextColor(0.5, 0.5, 0.5, 1)

    local toggleX = 50
    for i, mt in ipairs(MEDIA_TYPES) do
        local btn = CreateFrame("Button", nil, filterBar)
        local br, bg, bb = GetBadgeColor(mt.value)
        local labelWidth = mt.label:len() * 6 + 16

        btn:SetSize(labelWidth, 22)
        btn:SetPoint("LEFT", toggleX, 0)

        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()

        btn.borders = CreateBorder(btn, 1, br, bg, bb, 0.6)

        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.label:SetPoint("CENTER")
        btn.label:SetText(mt.label)

        btn.mediaType = mt.value

        local function UpdateToggleVisual()
            if typeFilters[mt.value] then
                btn.bg:SetColorTexture(br, bg, bb, 0.4)
                btn.label:SetTextColor(br + 0.3, bg + 0.3, bb + 0.3, 1)
                SetBorderColor(btn.borders, br, bg, bb, 0.6)
            else
                btn.bg:SetColorTexture(0.12, 0.12, 0.12, 0.5)
                btn.label:SetTextColor(0.4, 0.4, 0.4, 0.7)
                SetBorderColor(btn.borders, 0.2, 0.2, 0.2, 0.3)
            end
        end

        btn:SetScript("OnClick", function()
            typeFilters[mt.value] = not typeFilters[mt.value]
            UpdateToggleVisual()
            RefreshFindAssets()
        end)

        UpdateToggleVisual()

        typeToggleButtons[mt.value] = btn
        toggleX = toggleX + labelWidth + 4
    end

    -- Addon dropdown (styled)
    local filterAddonLabel = filterBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterAddonLabel:SetPoint("RIGHT", filterBar, "RIGHT", -190, 0)
    filterAddonLabel:SetText("Source Addon:")
    filterAddonLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local filterAddon = nil
    local addonDropdown = CreateStyledDropdown(filterBar, 140)
    addonDropdown:SetPoint("LEFT", filterAddonLabel, "RIGHT", 8, 0)

    -- Search bar
    local searchBar = CreateFrame("Frame", nil, tab2)
    searchBar:SetHeight(30)
    searchBar:SetPoint("TOPLEFT", 0, -58)
    searchBar:SetPoint("TOPRIGHT", 0, -58)

    searchBar.bg = searchBar:CreateTexture(nil, "BACKGROUND")
    searchBar.bg:SetAllPoints()
    searchBar.bg:SetColorTexture(0.08, 0.08, 0.08, 0.5)
    CreateBorder(searchBar, 1, 0.2, 0.2, 0.2, 0.5)

    local searchLabel = searchBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("LEFT", 8, 0)
    searchLabel:SetText("Search:")
    searchLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local searchBox = CreateStyledEditBox(searchBar, 250, 22)
    searchBox:SetPoint("LEFT", searchLabel, "RIGHT", 8, 0)

    local searchHint = searchBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchHint:SetPoint("LEFT", searchBox.container, "RIGHT", 10, 0)
    searchHint:SetText("Searches all addons by display name")
    searchHint:SetTextColor(0.4, 0.4, 0.4, 1)

    searchBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            RefreshFindAssets()
        end
    end)

    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    searchBox:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
        RefreshFindAssets()
    end)

    -- Column headers
    local headerRow = CreateFrame("Frame", nil, tab2)
    headerRow:SetHeight(22)
    headerRow:SetPoint("TOPLEFT", 0, -90)
    headerRow:SetPoint("TOPRIGHT", 0, -90)

    headerRow.bg = headerRow:CreateTexture(nil, "BACKGROUND")
    headerRow.bg:SetAllPoints()
    headerRow.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    local colType = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colType:SetPoint("LEFT", 8, 0)
    colType:SetText("TYPE")
    colType:SetTextColor(0.6, 0.6, 0.6, 1)

    local colName = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colName:SetPoint("LEFT", 85, 0)
    colName:SetText("DISPLAY NAME")
    colName:SetTextColor(0.6, 0.6, 0.6, 1)

    local colPath = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colPath:SetPoint("LEFT", 230, 0)
    colPath:SetText("FILE PATH")
    colPath:SetTextColor(0.6, 0.6, 0.6, 1)

    -- Scroll area
    local findArea = CreateFrame("Frame", nil, tab2)
    findArea:SetPoint("TOPLEFT", 0, -112)
    findArea:SetPoint("BOTTOMRIGHT", 0, 0)

    findArea.bg = findArea:CreateTexture(nil, "BACKGROUND")
    findArea.bg:SetAllPoints()
    findArea.bg:SetColorTexture(0.08, 0.08, 0.08, 0.5)
    CreateBorder(findArea, 1, 0.2, 0.2, 0.2, 0.5)

    local findScroll = CreateFrame("ScrollFrame", "GoomiMediaAssetsFindScroll", findArea, "UIPanelScrollFrameTemplate")
    findScroll:SetPoint("TOPLEFT", 5, -5)
    findScroll:SetPoint("BOTTOMRIGHT", -20, 5)

    StyleScrollBar("GoomiMediaAssetsFindScroll")

    local findChild = CreateFrame("Frame", nil, findScroll)
    findChild:SetSize(1, 1)
    findScroll:SetScrollChild(findChild)

    local findEmptyMsg = findArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    findEmptyMsg:SetPoint("CENTER")
    findEmptyMsg:SetText("No assets found for this filter.")
    findEmptyMsg:SetTextColor(0.4, 0.4, 0.4, 1)
    findEmptyMsg:Hide()

    -- Scan all media types
    local allResults = {}
    local allAddons = {}
    local scanned = false

    local function ScanAllLSM()
        if scanned then return end
        scanned = true

        local addonSet = {}

        for _, mt in ipairs(MEDIA_TYPES) do
            local hashTable = LSM:HashTable(mt.value)
            if hashTable then
                for name, path in pairs(hashTable) do
                    local addon = ExtractAddonName(path)

                    -- Skip WoW built-in assets (not useful for our purposes)
                    if addon == "WoW Default" then
                        -- skip
                    else
                        local pathStr
                        if type(path) == "number" then
                            pathStr = "FileDataID: " .. tostring(path)
                        else
                            pathStr = path
                        end

                        table.insert(allResults, {
                            displayName = name,
                            path = pathStr,
                            addon = addon,
                            mediaType = mt.value,
                        })
                        if not addonSet[addon] then
                            addonSet[addon] = true
                            table.insert(allAddons, addon)
                        end
                    end
                end
            end
        end

        table.sort(allResults, function(a, b)
            if a.mediaType ~= b.mediaType then
                return a.mediaType < b.mediaType
            end
            return a.displayName < b.displayName
        end)
        table.sort(allAddons)
    end

    RefreshFindAssets = function()
        ClearChildren(findChild)

        ScanAllLSM()

        local searchText = strtrim(searchBox:GetText()):lower()
        local isSearching = (searchText ~= "")

        local filtered = {}
        for _, r in ipairs(allResults) do
            if typeFilters[r.mediaType] then
                if isSearching then
                    -- Search mode: search all addons by display name
                    if r.displayName:lower():find(searchText, 1, true) then
                        table.insert(filtered, r)
                    end
                else
                    -- Normal mode: filter by selected addon
                    if r.addon == filterAddon then
                        table.insert(filtered, r)
                    end
                end
            end
        end

        if #filtered == 0 then
            findEmptyMsg:Show()
            findChild:SetHeight(1)
            return
        end
        findEmptyMsg:Hide()

        local ROW_HEIGHT = 30
        local yOff = 0

        for i, r in ipairs(filtered) do
            local row = CreateFrame("Frame", nil, findChild)
            row:SetSize(findChild:GetParent():GetWidth() - 10, ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 0, -yOff)

            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            row.bg:SetColorTexture(0.1, 0.1, 0.1, (i % 2 == 0) and 0.3 or 0.5)

            -- Type badge
            local badge = CreateFrame("Frame", nil, row)
            badge:SetSize(65, 18)
            badge:SetPoint("LEFT", 6, 0)

            local br, bg, bb = GetBadgeColor(r.mediaType)
            badge.bg = badge:CreateTexture(nil, "ARTWORK")
            badge.bg:SetAllPoints()
            badge.bg:SetColorTexture(br, bg, bb, 0.3)
            CreateBorder(badge, 1, br, bg, bb, 0.6)

            local badgeText = badge:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            badgeText:SetPoint("CENTER")
            badgeText:SetText(GetMediaLabel(r.mediaType))
            badgeText:SetTextColor(br + 0.3, bg + 0.3, bb + 0.3, 1)

            -- Display name
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("LEFT", 80, 0)
            nameText:SetWidth(140)
            nameText:SetJustifyH("LEFT")
            nameText:SetText(r.displayName)
            nameText:SetTextColor(1, 1, 1, 1)

            -- File path
            local pathText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            pathText:SetPoint("LEFT", 228, 0)
            pathText:SetPoint("RIGHT", row, "RIGHT", -55, 0)
            pathText:SetJustifyH("LEFT")
            pathText:SetText(r.path)
            pathText:SetTextColor(0.5, 0.5, 0.5, 1)
            pathText:SetWordWrap(false)

            -- Add or Edit button
            local isOwnAsset = (r.addon == "GoomiMediaAssets")
            local actionBtn = CreateStyledButton(row, 45, 20, isOwnAsset and "Edit" or "Add")
            actionBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)

            actionBtn:SetScript("OnClick", function()
                if isOwnAsset then
                    local foundIdx = nil
                    for ai, asset in ipairs(db.assets) do
                        if asset.displayName == r.displayName and asset.mediaType == r.mediaType then
                            foundIdx = ai
                            break
                        end
                    end

                    if foundIdx then
                        local asset = db.assets[foundIdx]
                        editingIndex = foundIdx
                        pendingSourcePath = asset.sourcePath
                        formTitle:SetText("EDIT ASSET")

                        formMediaType = asset.mediaType
                        typeDropdown:SetValue(asset.mediaType)

                        formDisplayName:SetText(asset.displayName)
                        formFileName:SetText(asset.fileName)
                        formCancelBtn:Show()

                        ShowTab(1)
                    end
                else
                    editingIndex = nil
                    pendingSourcePath = r.path
                    formMediaType = r.mediaType
                    typeDropdown:SetValue(r.mediaType)

                    formDisplayName:SetText(r.displayName)
                    formFileName:SetText(ExtractFileName(r.path))
                    formTitle:SetText("ADD NEW ASSET")
                    formCancelBtn:Show()

                    ShowTab(1)
                end
            end)

            yOff = yOff + ROW_HEIGHT + 1
        end

        findChild:SetHeight(math.max(yOff, 1))
    end

    -- Addon dropdown init
    local function InitAddonDropdown()
        ScanAllLSM()

        local addonOptions = {}
        for _, addon in ipairs(allAddons) do
            table.insert(addonOptions, { value = addon, label = addon })
        end

        addonDropdown:SetOptions(addonOptions)

        -- Default to first addon alphabetically
        local defaultAddon = allAddons[1] or ""
        filterAddon = defaultAddon
        addonDropdown:SetValue(defaultAddon)

        addonDropdown:SetCallback(function(value)
            filterAddon = value
            RefreshFindAssets()
        end)
    end

    ScanAllLSM()
    InitAddonDropdown()
    RefreshFindAssets()

    -- ==============================
    -- Tab 3: Guide
    -- ==============================
    local tab3 = tabs[3]
    local infoY = 0

    local function InfoHeader(text)
        local fs = tab3:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        fs:SetPoint("TOPLEFT", 0, -infoY)
        fs:SetText(text)
        fs:SetTextColor(1, 1, 1, 1)
        infoY = infoY + 22
    end

    local function InfoText(text)
        local fs = tab3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", 0, -infoY)
        fs:SetWidth(700)
        fs:SetJustifyH("LEFT")
        fs:SetText(text)
        fs:SetTextColor(0.7, 0.7, 0.7, 1)
        infoY = infoY + (fs:GetStringHeight() or 14) + 8
    end

    InfoHeader("Goomi Media Assets Purpose")
    InfoText("Goomi Media Assets registers your custom textures, sounds, and fonts with LibSharedMedia so any addon can use them. No Lua editing required.  Additionally you can save assets from other addons if you want to remove that addon without losing a particular asset.")
    infoY = infoY + 6
    InfoHeader("Adding Your Own Files")
    InfoText("1.  Place your file (.tga, .blp, .ogg, .mp3, .ttf) into the GoomiMediaAssets/assets/ folder.\n2.  Go to the My Assets tab and fill out the form: pick a type, give it a display name, and enter the exact filename.\n3.  Click Save. The asset is immediately available in any addon that uses LibSharedMedia.\n\nNote: Sounds and fonts require the file extension (e.g. MySound.ogg, MyFont.ttf). Textures work with or without it.")
    infoY = infoY + 6
    InfoHeader("Grabbing Assets From Other Addons that use LibSharedMedia")
    InfoText("1.  Go to the Find Assets tab and select an addon from the dropdown.\n2.  Find an asset you like and click Add — the form on My Assets will be pre-filled.\n3.  Review the name, then click Save.\n4.  Copy the original file from that addon's folder into GoomiMediaAssets/assets/.\n5.  You can now uninstall the original addon and keep the asset.")
    infoY = infoY + 6
    InfoHeader("Grabbing Assets That Aren't Listed in 'Find Assets'")
    InfoText("The Find Assets tab only shows addons that register their media through LibSharedMedia (LSM). Most popular addons do this (Plater, ElvUI, Details, SharedMedia packs, etc.), but some addons include textures, sounds, or fonts without registering them. If you know an addon has a file you want but it doesn't appear in Find Assets, you can still add it manually — just copy the file into GoomiMediaAssets/assets/ and follow the 'Adding Your Own Files' steps above.")
    infoY = infoY + 6
    InfoHeader("Bonus Sounds")
    InfoText("With WeakAuras no longer supported on retail, if you are missing having access to their sounds you can add them back with Goomi Media Assets.\n\n1.  Type  /gma wasounds  to populate 100+ WeakAuras sound presets. \n2. Copy the .ogg files from your old WeakAuras install into GoomiMediaAssets/assets/ to activate them.\n\nWeakAura Sounds exist in 2 places WeakAuras/Media/Sounds and WeakAuras/PowerAurasMedia/Sounds")
    infoY = infoY + 6
    InfoHeader("Commands")
    InfoText("/gma  — Open this window\n/gma wasounds  — Add WeakAuras sound presets")

    ShowTab(1)
end

-- ========================
-- Open Settings
-- ========================
local function OpenSettings()
    local frame = CreateSettingsFrame()
    BuildSettingsContent(frame.content)
    frame:Show()
end

-- ========================
-- Slash Commands
-- ========================
SLASH_GOOMIMEDIAASSETS1 = "/gma"
SlashCmdList["GOOMIMEDIAASSETS"] = function(msg)
    msg = strtrim(msg or ""):lower()

    if msg == "wasounds" then
        PopulateWASounds()
    else
        OpenSettings()
    end
end

-- ========================
-- Initialization
-- ========================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "GoomiMediaAssets" then
        InitDB()
        RegisterAllAssets()
        print("GoomiMediaAssets loaded! Type /gma to open settings.")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
