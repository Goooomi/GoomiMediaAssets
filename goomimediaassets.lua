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
    return path:match("([^\\]+)$") or path
end

local function ExtractAddonName(path)
    local addon = path:match("Interface\\AddOns\\([^\\]+)")
    return addon or "Built-in"
end

-- ========================
-- Database
-- ========================
local function InitDB()
    local db = GoomiMediaAssetsDB
    if not db.assets then db.assets = {} end
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
-- Copy-to-Clipboard Popup
-- ========================
local copyFrame = nil

local function ShowCopyPopup(text)
    if not copyFrame then
        copyFrame = CreateFrame("Frame", "GoomiMediaAssetsCopyFrame", UIParent, "BackdropTemplate")
        copyFrame:SetSize(550, 70)
        copyFrame:SetPoint("CENTER", 0, 200)
        copyFrame:SetFrameStrata("DIALOG")
        copyFrame:SetFrameLevel(500)
        copyFrame:SetMovable(true)
        copyFrame:EnableMouse(true)
        copyFrame:RegisterForDrag("LeftButton")
        copyFrame:SetScript("OnDragStart", copyFrame.StartMoving)
        copyFrame:SetScript("OnDragStop", copyFrame.StopMovingOrSizing)
        copyFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 2,
        })
        copyFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.98)
        copyFrame:SetBackdropBorderColor(0.3, 0.5, 0.7, 1)

        local label = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("TOPLEFT", 10, -8)
        label:SetText("Ctrl+C to copy, then Escape to close:")
        label:SetTextColor(0.7, 0.7, 0.7, 1)

        copyFrame.editBox = CreateFrame("EditBox", nil, copyFrame, "InputBoxTemplate")
        copyFrame.editBox:SetPoint("TOPLEFT", 12, -28)
        copyFrame.editBox:SetPoint("BOTTOMRIGHT", -12, 10)
        copyFrame.editBox:SetAutoFocus(true)
        copyFrame.editBox:SetFontObject("ChatFontNormal")

        copyFrame.editBox:SetScript("OnEscapePressed", function()
            copyFrame:Hide()
        end)

        copyFrame.editBox:SetScript("OnMouseUp", function(self)
            self:HighlightText()
        end)
    end

    copyFrame.editBox:SetText(text)
    copyFrame:Show()
    copyFrame.editBox:SetFocus()
    copyFrame.editBox:HighlightText()
end

-- ========================
-- Shared UI Helpers
-- ========================
local function CreateBorder(parent, thickness, r, g, b, a)
    thickness = thickness or 1
    r, g, b, a = r or 0, g or 0, b or 0, a or 1

    local top = parent:CreateTexture(nil, "OVERLAY")
    top:SetColorTexture(r, g, b, a)
    top:SetHeight(thickness)
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")

    local bottom = parent:CreateTexture(nil, "OVERLAY")
    bottom:SetColorTexture(r, g, b, a)
    bottom:SetHeight(thickness)
    bottom:SetPoint("BOTTOMLEFT")
    bottom:SetPoint("BOTTOMRIGHT")

    local left = parent:CreateTexture(nil, "OVERLAY")
    left:SetColorTexture(r, g, b, a)
    left:SetWidth(thickness)
    left:SetPoint("TOPLEFT")
    left:SetPoint("BOTTOMLEFT")

    local right = parent:CreateTexture(nil, "OVERLAY")
    right:SetColorTexture(r, g, b, a)
    right:SetWidth(thickness)
    right:SetPoint("TOPRIGHT")
    right:SetPoint("BOTTOMRIGHT")
end

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

    -- Main frame
    local frame = CreateFrame("Frame", "GoomiMediaAssetsSettingsFrame", UIParent)
    frame:SetSize(700, 550)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH")
    frame:Hide()

    -- Close on Escape
    table.insert(UISpecialFrames, "GoomiMediaAssetsSettingsFrame")

    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)

    -- Border
    CreateBorder(frame, 2, 0.2, 0.2, 0.2, 1)

    -- Title bar
    frame.titleBar = CreateFrame("Frame", nil, frame)
    frame.titleBar:SetHeight(40)
    frame.titleBar:SetPoint("TOPLEFT", 0, 0)
    frame.titleBar:SetPoint("TOPRIGHT", 0, 0)

    frame.titleBar.bg = frame.titleBar:CreateTexture(nil, "BACKGROUND")
    frame.titleBar.bg:SetAllPoints()
    frame.titleBar.bg:SetColorTexture(0.1, 0.1, 0.1, 1)

    -- Title bar bottom border
    frame.titleBar.border = frame.titleBar:CreateTexture(nil, "OVERLAY")
    frame.titleBar.border:SetColorTexture(0.3, 0.3, 0.3, 1)
    frame.titleBar.border:SetHeight(1)
    frame.titleBar.border:SetPoint("BOTTOMLEFT")
    frame.titleBar.border:SetPoint("BOTTOMRIGHT")

    -- Title text
    frame.title = frame.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("LEFT", 15, 0)
    frame.title:SetText("MEDIA ASSETS")
    frame.title:SetTextColor(1, 1, 1, 1)

    -- Close button
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

    -- Content area (below title bar, with padding)
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

    -- LSM warning if not available
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

    local tabNames = { "My Assets", "Find Assets" }
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

    -- Tab content frames
    for i = 1, 2 do
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
    local formDisplayName
    local formFileName
    local formSaveBtn
    local formCancelBtn
    local formTitle
    local editingIndex = nil
    local pendingSourcePath = nil

    -- ==============================
    -- Tab 1: My Assets
    -- ==============================
    local tab1 = tabs[1]

    local tab1Desc = tab1:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tab1Desc:SetPoint("TOPLEFT", 0, 0)
    tab1Desc:SetWidth(600)
    tab1Desc:SetJustifyH("LEFT")
    tab1Desc:SetText("Register your own files with LibSharedMedia. Drop files into the addon's assets/ folder, then add them here.")
    tab1Desc:SetTextColor(0.5, 0.5, 0.5, 1)

    -- Scroll area for asset list
    local listArea = CreateFrame("Frame", nil, tab1)
    listArea:SetPoint("TOPLEFT", 0, -22)
    listArea:SetPoint("BOTTOMRIGHT", 0, 180)

    listArea.bg = listArea:CreateTexture(nil, "BACKGROUND")
    listArea.bg:SetAllPoints()
    listArea.bg:SetColorTexture(0.08, 0.08, 0.08, 0.5)
    CreateBorder(listArea, 1, 0.2, 0.2, 0.2, 0.5)

    local listScroll = CreateFrame("ScrollFrame", "GoomiMediaAssetsListScroll", listArea, "UIPanelScrollFrameTemplate")
    listScroll:SetPoint("TOPLEFT", 5, -5)
    listScroll:SetPoint("BOTTOMRIGHT", -25, 5)

    local listScrollBar = _G["GoomiMediaAssetsListScrollScrollBar"]
    if listScrollBar then
        listScrollBar:GetThumbTexture():SetColorTexture(0.3, 0.3, 0.3, 0.8)
        listScrollBar:GetThumbTexture():SetSize(8, 40)
        listScrollBar:SetWidth(8)
    end

    local listChild = CreateFrame("Frame", nil, listScroll)
    listChild:SetSize(1, 1)
    listScroll:SetScrollChild(listChild)

    -- Empty list message
    local emptyMsg = listArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyMsg:SetPoint("CENTER")
    emptyMsg:SetText("No assets registered yet. Use the form below to add one.")
    emptyMsg:SetTextColor(0.4, 0.4, 0.4, 1)

    -- Build the asset list rows
    RefreshMyAssets = function()
        ClearChildren(listChild)
        local assets = db.assets

        if #assets == 0 then
            emptyMsg:Show()
            listChild:SetHeight(1)
            return
        end
        emptyMsg:Hide()

        local ROW_HEIGHT = 34
        local yOff = 0

        for idx, asset in ipairs(assets) do
            local row = CreateFrame("Frame", nil, listChild)
            row:SetSize(listChild:GetParent():GetWidth() - 10, ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 0, -yOff)

            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            row.bg:SetColorTexture(0.1, 0.1, 0.1, (idx % 2 == 0) and 0.3 or 0.5)

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
            nameText:SetWidth(150)
            nameText:SetJustifyH("LEFT")
            nameText:SetText(asset.displayName)
            nameText:SetTextColor(1, 1, 1, 1)

            -- Filename
            local fileText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fileText:SetPoint("LEFT", nameText, "RIGHT", 8, 0)
            fileText:SetWidth(150)
            fileText:SetJustifyH("LEFT")
            fileText:SetText(asset.fileName)
            fileText:SetTextColor(0.6, 0.6, 0.6, 1)

            -- Info button (source tooltip)
            local infoBtn = CreateFrame("Button", nil, row)
            infoBtn:SetSize(20, 20)
            infoBtn:SetPoint("LEFT", fileText, "RIGHT", 6, 0)

            infoBtn.text = infoBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            infoBtn.text:SetPoint("CENTER")
            infoBtn.text:SetText("i")
            infoBtn.text:SetTextColor(0.4, 0.6, 0.8, 1)

            infoBtn.bg = infoBtn:CreateTexture(nil, "BACKGROUND")
            infoBtn.bg:SetAllPoints()
            infoBtn.bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)

            local sourcePath = asset.sourcePath
            local sourceLabel = sourcePath and sourcePath or "User Added"

            infoBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Source", 1, 1, 1)
                GameTooltip:AddLine(sourceLabel, 0.7, 0.7, 0.7, true)
                if sourcePath then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Click to copy path", 0.4, 0.6, 0.8)
                end
                GameTooltip:Show()
                self.bg:SetColorTexture(0.25, 0.25, 0.25, 0.8)
            end)

            infoBtn:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
                self.bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
            end)

            infoBtn:SetScript("OnClick", function()
                if sourcePath then
                    ShowCopyPopup(sourcePath)
                end
            end)

            -- Edit button
            local editBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            editBtn:SetSize(45, 22)
            editBtn:SetPoint("RIGHT", row, "RIGHT", -55, 0)
            editBtn:SetText("Edit")

            editBtn:SetScript("OnClick", function()
                editingIndex = idx
                pendingSourcePath = asset.sourcePath
                formTitle:SetText("EDIT ASSET")

                formMediaType = asset.mediaType
                UIDropDownMenu_SetText(_G["GoomiMediaAssetsTypeDropdown"], GetMediaLabel(asset.mediaType))

                formDisplayName:SetText(asset.displayName)
                formFileName:SetText(asset.fileName)
                formCancelBtn:Show()
            end)

            -- Delete button
            local delBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            delBtn:SetSize(50, 22)
            delBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)
            delBtn:SetText("Delete")

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
    -- Tab 1: Add/Edit Form
    -- ==============================
    local formArea = CreateFrame("Frame", nil, tab1)
    formArea:SetHeight(170)
    formArea:SetPoint("BOTTOMLEFT", 0, 0)
    formArea:SetPoint("BOTTOMRIGHT", 0, 0)

    formArea.bg = formArea:CreateTexture(nil, "BACKGROUND")
    formArea.bg:SetAllPoints()
    formArea.bg:SetColorTexture(0.08, 0.08, 0.08, 0.5)
    CreateBorder(formArea, 1, 0.2, 0.2, 0.2, 0.5)

    -- Form title
    formTitle = formArea:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    formTitle:SetPoint("TOPLEFT", 10, -10)
    formTitle:SetText("ADD NEW ASSET")
    formTitle:SetTextColor(1, 1, 1, 1)

    -- Row 1: Media Type dropdown
    local typeLabel = formArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    typeLabel:SetPoint("TOPLEFT", 10, -38)
    typeLabel:SetText("Type:")
    typeLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    formMediaType = "statusbar"

    local fileHint

    local typeDropdown = CreateFrame("Frame", "GoomiMediaAssetsTypeDropdown", formArea, "UIDropDownMenuTemplate")
    typeDropdown:SetPoint("LEFT", typeLabel, "RIGHT", -5, -2)
    UIDropDownMenu_SetWidth(typeDropdown, 100)

    UIDropDownMenu_Initialize(typeDropdown, function(self, level)
        for _, mt in ipairs(MEDIA_TYPES) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = mt.label
            info.checked = (formMediaType == mt.value)
            info.func = function()
                formMediaType = mt.value
                UIDropDownMenu_SetText(typeDropdown, mt.label)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(typeDropdown, GetMediaLabel(formMediaType))

    -- Row 2: Display Name
    local nameLabel = formArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", 10, -70)
    nameLabel:SetText("Display Name:")
    nameLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    formDisplayName = CreateFrame("EditBox", nil, formArea, "InputBoxTemplate")
    formDisplayName:SetSize(200, 24)
    formDisplayName:SetPoint("LEFT", nameLabel, "RIGHT", 8, 0)
    formDisplayName:SetAutoFocus(false)

    formDisplayName:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    formDisplayName:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Row 2 continued: File Name
    local fileLabel = formArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fileLabel:SetPoint("LEFT", formDisplayName, "RIGHT", 20, 0)
    fileLabel:SetText("File Name:")
    fileLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    formFileName = CreateFrame("EditBox", nil, formArea, "InputBoxTemplate")
    formFileName:SetSize(170, 24)
    formFileName:SetPoint("LEFT", fileLabel, "RIGHT", 8, 0)
    formFileName:SetAutoFocus(false)

    formFileName:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    formFileName:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Hint under filename
    fileHint = formArea:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fileHint:SetPoint("TOPLEFT", 10, -96)
    fileHint:SetWidth(580)
    fileHint:SetJustifyH("LEFT")
    fileHint:SetText("File must exist in GoomiMediaAssets/assets/")
    fileHint:SetTextColor(0.4, 0.4, 0.4, 1)

    -- Row 3: Buttons
    formSaveBtn = CreateFrame("Button", nil, formArea, "UIPanelButtonTemplate")
    formSaveBtn:SetSize(80, 28)
    formSaveBtn:SetPoint("TOPLEFT", 10, -115)
    formSaveBtn:SetText("Save")

    formCancelBtn = CreateFrame("Button", nil, formArea, "UIPanelButtonTemplate")
    formCancelBtn:SetSize(80, 28)
    formCancelBtn:SetPoint("LEFT", formSaveBtn, "RIGHT", 10, 0)
    formCancelBtn:SetText("Cancel")
    formCancelBtn:Hide()

    -- Save handler
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

        -- Register with LSM immediately
        if LSM then
            local path = ASSETS_PATH .. entry.fileName
            LSM:Register(entry.mediaType, entry.displayName, path)
        end

        -- Reset form
        editingIndex = nil
        pendingSourcePath = nil
        formTitle:SetText("ADD NEW ASSET")
        formDisplayName:SetText("")
        formFileName:SetText("")
        formCancelBtn:Hide()

        RefreshMyAssets()
    end)

    -- Cancel handler
    formCancelBtn:SetScript("OnClick", function()
        editingIndex = nil
        pendingSourcePath = nil
        formTitle:SetText("ADD NEW ASSET")
        formDisplayName:SetText("")
        formFileName:SetText("")
        formCancelBtn:Hide()
    end)

    -- Initial list population
    RefreshMyAssets()

    -- ==============================
    -- Tab 2: Find Assets
    -- ==============================
    local tab2 = tabs[2]

    local tab2Desc = tab2:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tab2Desc:SetPoint("TOPLEFT", 0, 0)
    tab2Desc:SetWidth(600)
    tab2Desc:SetJustifyH("LEFT")
    tab2Desc:SetText("Browse assets registered by other addons. Click a file path to copy it, then use Add to pre-fill the form on My Assets.")
    tab2Desc:SetTextColor(0.5, 0.5, 0.5, 1)

    -- Filter row
    local filterRow = CreateFrame("Frame", nil, tab2)
    filterRow:SetSize(600, 36)
    filterRow:SetPoint("TOPLEFT", 0, -20)

    filterRow.bg = filterRow:CreateTexture(nil, "BACKGROUND")
    filterRow.bg:SetAllPoints()
    filterRow.bg:SetColorTexture(0.08, 0.08, 0.08, 0.5)
    CreateBorder(filterRow, 1, 0.2, 0.2, 0.2, 0.5)

    -- Media type filter dropdown
    local filterTypeLabel = filterRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterTypeLabel:SetPoint("LEFT", 8, 0)
    filterTypeLabel:SetText("Type:")
    filterTypeLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local filterMediaType = "statusbar"

    local filterTypeDropdown = CreateFrame("Frame", "GoomiMediaAssetsFindTypeDD", filterRow, "UIDropDownMenuTemplate")
    filterTypeDropdown:SetPoint("LEFT", filterTypeLabel, "RIGHT", -5, 0)
    UIDropDownMenu_SetWidth(filterTypeDropdown, 100)

    -- Addon filter dropdown
    local filterAddonLabel = filterRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterAddonLabel:SetPoint("LEFT", filterTypeDropdown, "RIGHT", 10, 0)
    filterAddonLabel:SetText("Addon:")
    filterAddonLabel:SetTextColor(0.8, 0.8, 0.8, 1)

    local filterAddon = "All"

    local filterAddonDropdown = CreateFrame("Frame", "GoomiMediaAssetsFindAddonDD", filterRow, "UIDropDownMenuTemplate")
    filterAddonDropdown:SetPoint("LEFT", filterAddonLabel, "RIGHT", -5, 0)
    UIDropDownMenu_SetWidth(filterAddonDropdown, 130)

    -- Find Assets scroll area
    local findArea = CreateFrame("Frame", nil, tab2)
    findArea:SetPoint("TOPLEFT", 0, -60)
    findArea:SetPoint("BOTTOMRIGHT", 0, 0)

    findArea.bg = findArea:CreateTexture(nil, "BACKGROUND")
    findArea.bg:SetAllPoints()
    findArea.bg:SetColorTexture(0.08, 0.08, 0.08, 0.5)
    CreateBorder(findArea, 1, 0.2, 0.2, 0.2, 0.5)

    local findScroll = CreateFrame("ScrollFrame", "GoomiMediaAssetsFindScroll", findArea, "UIPanelScrollFrameTemplate")
    findScroll:SetPoint("TOPLEFT", 5, -5)
    findScroll:SetPoint("BOTTOMRIGHT", -25, 5)

    local findScrollBar = _G["GoomiMediaAssetsFindScrollScrollBar"]
    if findScrollBar then
        findScrollBar:GetThumbTexture():SetColorTexture(0.3, 0.3, 0.3, 0.8)
        findScrollBar:GetThumbTexture():SetSize(8, 40)
        findScrollBar:SetWidth(8)
    end

    local findChild = CreateFrame("Frame", nil, findScroll)
    findChild:SetSize(1, 1)
    findScroll:SetScrollChild(findChild)

    local findEmptyMsg = findArea:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    findEmptyMsg:SetPoint("CENTER")
    findEmptyMsg:SetText("No assets found for this filter.")
    findEmptyMsg:SetTextColor(0.4, 0.4, 0.4, 1)
    findEmptyMsg:Hide()

    -- Scan LSM for all assets of a given type and build addon list
    local cachedScan = {}
    local cachedAddons = {}

    local function ScanLSM(mediaType)
        local results = {}
        local addons = {}
        local addonSet = {}

        local hashTable = LSM:HashTable(mediaType)
        if hashTable then
            for name, path in pairs(hashTable) do
                local addon = ExtractAddonName(path)
                table.insert(results, {
                    displayName = name,
                    path = path,
                    addon = addon,
                    mediaType = mediaType,
                })
                if not addonSet[addon] then
                    addonSet[addon] = true
                    table.insert(addons, addon)
                end
            end
        end

        table.sort(results, function(a, b) return a.displayName < b.displayName end)
        table.sort(addons)

        cachedScan[mediaType] = results
        cachedAddons[mediaType] = addons
    end

    local function RefreshFindAssets()
        ClearChildren(findChild)

        if not cachedScan[filterMediaType] then
            ScanLSM(filterMediaType)
        end

        local results = cachedScan[filterMediaType] or {}
        local filtered = {}

        for _, r in ipairs(results) do
            if filterAddon == "All" or r.addon == filterAddon then
                table.insert(filtered, r)
            end
        end

        if #filtered == 0 then
            findEmptyMsg:Show()
            findChild:SetHeight(1)
            return
        end
        findEmptyMsg:Hide()

        local ROW_HEIGHT = 32
        local yOff = 0

        for i, r in ipairs(filtered) do
            local row = CreateFrame("Frame", nil, findChild)
            row:SetSize(findChild:GetParent():GetWidth() - 10, ROW_HEIGHT)
            row:SetPoint("TOPLEFT", 0, -yOff)

            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            row.bg:SetColorTexture(0.1, 0.1, 0.1, (i % 2 == 0) and 0.3 or 0.5)

            -- Display name
            local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameText:SetPoint("LEFT", 8, 0)
            nameText:SetWidth(140)
            nameText:SetJustifyH("LEFT")
            nameText:SetText(r.displayName)
            nameText:SetTextColor(1, 1, 1, 1)

            -- File path (clickable)
            local pathBtn = CreateFrame("Button", nil, row)
            pathBtn:SetPoint("LEFT", nameText, "RIGHT", 8, 0)
            pathBtn:SetPoint("RIGHT", row, "RIGHT", -65, 0)
            pathBtn:SetHeight(ROW_HEIGHT)

            local pathText = pathBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            pathText:SetAllPoints()
            pathText:SetJustifyH("LEFT")
            pathText:SetText(r.path)
            pathText:SetTextColor(0.4, 0.6, 0.8, 1)
            pathText:SetWordWrap(false)

            pathBtn:SetScript("OnEnter", function()
                pathText:SetTextColor(0.6, 0.8, 1, 1)
                GameTooltip:SetOwner(pathBtn, "ANCHOR_BOTTOM")
                GameTooltip:AddLine("Click to copy path", 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end)
            pathBtn:SetScript("OnLeave", function()
                pathText:SetTextColor(0.4, 0.6, 0.8, 1)
                GameTooltip:Hide()
            end)
            pathBtn:SetScript("OnClick", function()
                ShowCopyPopup(r.path)
            end)

            -- Add button
            local addBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            addBtn:SetSize(50, 22)
            addBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
            addBtn:SetText("Add")

            addBtn:SetScript("OnClick", function()
                -- Pre-fill form on Tab 1 and switch
                editingIndex = nil
                pendingSourcePath = r.path
                formMediaType = r.mediaType
                UIDropDownMenu_SetText(typeDropdown, GetMediaLabel(r.mediaType))

                formDisplayName:SetText(r.displayName)
                formFileName:SetText(ExtractFileName(r.path))
                formTitle:SetText("ADD NEW ASSET")
                formCancelBtn:Show()

                ShowTab(1)
            end)

            yOff = yOff + ROW_HEIGHT + 1
        end

        findChild:SetHeight(math.max(yOff, 1))
    end

    -- Initialize filter type dropdown
    UIDropDownMenu_Initialize(filterTypeDropdown, function(self, level)
        for _, mt in ipairs(MEDIA_TYPES) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = mt.label
            info.checked = (filterMediaType == mt.value)
            info.func = function()
                filterMediaType = mt.value
                UIDropDownMenu_SetText(filterTypeDropdown, mt.label)

                -- Reset addon filter and rescan
                filterAddon = "All"
                UIDropDownMenu_SetText(filterAddonDropdown, "All")
                cachedScan[mt.value] = nil
                ScanLSM(mt.value)
                RefreshFindAssets()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetText(filterTypeDropdown, GetMediaLabel(filterMediaType))

    -- Initialize addon filter dropdown
    local function InitAddonDropdown()
        if not cachedAddons[filterMediaType] then
            ScanLSM(filterMediaType)
        end

        UIDropDownMenu_Initialize(filterAddonDropdown, function(self, level)
            local allInfo = UIDropDownMenu_CreateInfo()
            allInfo.text = "All"
            allInfo.checked = (filterAddon == "All")
            allInfo.func = function()
                filterAddon = "All"
                UIDropDownMenu_SetText(filterAddonDropdown, "All")
                RefreshFindAssets()
            end
            UIDropDownMenu_AddButton(allInfo)

            local addons = cachedAddons[filterMediaType] or {}
            for _, addon in ipairs(addons) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = addon
                info.checked = (filterAddon == addon)
                info.func = function()
                    filterAddon = addon
                    UIDropDownMenu_SetText(filterAddonDropdown, addon)
                    RefreshFindAssets()
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetText(filterAddonDropdown, filterAddon)
    end

    -- Initial scan and populate
    ScanLSM(filterMediaType)
    InitAddonDropdown()

    -- ==============================
    -- Clear All Button
    -- ==============================
    local resetBtn = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 30)
    resetBtn:SetPoint("BOTTOMRIGHT", 0, 0)
    resetBtn:SetText("Clear All")

    resetBtn:SetScript("OnClick", function()
        StaticPopupDialogs["GOOMI_MEDIA_CLEAR_ALL"] = {
            text = "Remove all registered media assets? This cannot be undone.",
            button1 = "Yes",
            button2 = "No",
            OnAccept = function()
                wipe(db.assets)
                editingIndex = nil
                pendingSourcePath = nil
                formTitle:SetText("ADD NEW ASSET")
                formDisplayName:SetText("")
                formFileName:SetText("")
                formCancelBtn:Hide()
                RefreshMyAssets()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show("GOOMI_MEDIA_CLEAR_ALL")
    end)

    -- Show Tab 1 by default
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
SLASH_GOOMIMEDIAASSETS2 = "/mediaassets"
SlashCmdList["GOOMIMEDIAASSETS"] = function(msg)
    OpenSettings()
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

-- ========================
-- GoomiUI Integration (optional)
-- ========================
-- If GoomiUI is present, register as a module so it also appears in the GoomiUI settings panel
if GoomiUI and GoomiUI.RegisterModule then
    local GoomiUIBridge = {
        name = "Media Assets",
        version = "1.0",
    }

    function GoomiUIBridge:OnLoad() end
    function GoomiUIBridge:OnEnable() end
    function GoomiUIBridge:OnDisable() end

    function GoomiUIBridge:CreateSettings(parentFrame)
        local text = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("TOPLEFT", 0, 0)
        text:SetWidth(550)
        text:SetJustifyH("LEFT")
        text:SetText("Media Assets has its own settings window.")
        text:SetTextColor(0.8, 0.8, 0.8, 1)

        local openBtn = CreateFrame("Button", nil, parentFrame, "UIPanelButtonTemplate")
        openBtn:SetSize(160, 30)
        openBtn:SetPoint("TOPLEFT", 0, -30)
        openBtn:SetText("Open Media Assets")
        openBtn:SetScript("OnClick", function() OpenSettings() end)

        local hint = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOPLEFT", 0, -70)
        hint:SetText("You can also type /gma")
        hint:SetTextColor(0.5, 0.5, 0.5, 1)
    end

    GoomiUI:RegisterModule("Media Assets", GoomiUIBridge)
end
