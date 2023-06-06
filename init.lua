local _, core = ...; -- Namespace
local AceGUI = LibStub("AceGUI-3.0")
ProjectDMG = LibStub("AceAddon-3.0"):NewAddon("ProjectDMG", "AceConsole-3.0", "AceEvent-3.0")
--------------------------------------
-- Custom Slash Command
--------------------------------------
function core:Print(string)
    local hex = select(4, core.Config:GetThemeColor());
    local prefix = string.format("|cff%s%s|r", hex:upper(), "Project DMG:");

    DEFAULT_CHAT_FRAME:AddMessage(string.join(" ", prefix, string or "nil"));
end

core.commands = {
    -- ["config"] = core.Config.Toggle, -- this is a function (no/ knowledge of Config object)
    ["config"] = function()
        InterfaceOptionsFrame_OpenToCategory(core.optionsFrame)
        InterfaceOptionsFrame_OpenToCategory(core.optionsFrame)
    end,
    ["help"] = function()
        print(" ");
        core:Print("List of slash commands:")
        core:Print("|cff00a0e9/pdmg config|r - shows config menu");
        core:Print("|cff00a0e9/pdmg help|r - shows help info");
        print(" ");
    end,

    ["edit"] = function()
        ProjectDMG:setEditMode(nil, not ProjectDMG:isEditMode())
    end
};

core.castSpells = {
    displayFramePool = {},
    displayFrameHeight = 20,
    displayFrameWidth = 250,
    containerWidth = 250,
    containerHeight = 200,
    iconWidth = 20,
    iconHeight = 20,
}

core.dimensions = {
    horizontal = {
        containerWidth = 250,
        containerHeight = 50,
        iconWidth = 50,
        iconHeight = 50,
        oneSpellFrameWidth = 50,
    },
    vertical = {
        containerWidth = 150,
        containerHeight = 250,
        iconWidth = 25,
        iconHeight = 25,
        oneSpellFrameHeight = 25,
    }
}

local options = {
    name = "ProjectDMG",
    handler = ProjectDMG,
    type = "group",
    args = {
        spellNameToggle = {
            type = "toggle",
            name = "Display Spell Name",
            desc = "Toggles the display of the spell name.",
            get = "isSpellNameShown",
            set = "setSpellNameShown",
        },
        editMode = {
            type = "toggle",
            name = "Edit Mode",
            desc = "Toggles edit mode.",
            get = "isEditMode",
            set = "setEditMode",
        },
        horizontal = {
            type = "toggle",
            name = "Horizontal",
            desc = "Toggles horizontal mode.",
            get = "isHorizontal",
            set = "setHorizontal",
        },
    },
}

local defaultConfigs = {
    profile = {
        isSpellNameShown = true,
        isEditMode = false,
        isHorizontal = false,
        containerPoints = {
            point = "CENTER",
            relativePoint = "CENTER",
            xOfs = 0,
            yOfs = 0,
            containerWidth = core.dimensions.vertical.containerWidth,
            containerHeight = core.dimensions.vertical.containerHeight,
        }
    }
}


local function saveContainerPoints(frame)
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint()
    ProjectDMG.db.profile.containerPoints = {
        point = point,
        relativePoint = relativePoint,
        xOfs = xOfs,
        yOfs = yOfs,
        containerWidth = frame:GetWidth(),
        containerHeight = frame:GetHeight(),
    }
end

local function getTotalNumberOfFrames(frame)
    return ProjectDMG.db.profile.isHorizontal and
        math.floor(frame:GetWidth() / frame:GetHeight()) or
        math.floor(frame:GetHeight() / core.dimensions.vertical.oneSpellFrameHeight);
end

function ProjectDMG:initDamageDisplayFramePool(damageTrackerFrame)
    local totalNumberOfFrames = getTotalNumberOfFrames(damageTrackerFrame);

    local currentNumberOfFrames = #core.castSpells.displayFramePool;
    local spellFrameHeight = ProjectDMG.db.profile.isHorizontal and damageTrackerFrame:GetHeight() or
        core.dimensions.vertical.oneSpellFrameHeight;
    local iconWidth = ProjectDMG.db.profile.isHozirontal and core.dimensions.horizontal.iconWidth or
        core.dimensions.vertical.iconWidth;
    local iconHeight = iconWidth
    if (totalNumberOfFrames < currentNumberOfFrames) then
        for i = totalNumberOfFrames + 1, currentNumberOfFrames do
            core.castSpells.displayFramePool[i].container:Hide();
        end
    else
        for i = currentNumberOfFrames + 1, totalNumberOfFrames do
            local spellFrame = CreateFrame("Frame", nil, damageTrackerFrame);
            spellFrame:ClearAllPoints();
            spellFrame:SetHeight(spellFrameHeight);
            local spellIcon = spellFrame:CreateTexture(nil, "ARTWORK");
            spellIcon:SetSize(iconWidth, iconHeight);
            spellIcon:SetPoint("TOPLEFT", spellFrame, 0, 0);
            local spellText = spellFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal");
            spellText:SetAllPoints(spellFrame);
            spellText:SetPoint("TOPLEFT", spellIcon, 5, 0);

            table.insert(core.castSpells.displayFramePool,
                { container = spellFrame, iconFrame = spellIcon, textFrame = spellText });
        end
    end

    for i = 1, totalNumberOfFrames do
        local container = core.castSpells.displayFramePool[i].container;
        container:SetHeight(spellFrameHeight);
        container:Show();
        core.castSpells.displayFramePool[i].iconFrame:SetSize(iconWidth, iconHeight);
        if self.db.profile.isHorizontal then
            core.castSpells.displayFramePool[i].textFrame:Hide();
        else
            core.castSpells.displayFramePool[i].textFrame:Show();
        end
    end
end

-- Create a frame to hold the damage tracker window
local damageTrackerFrame = CreateFrame("Frame", "PDamageTrackerFrame", UIParent)

damageTrackerFrame:SetMovable(false);
damageTrackerFrame:SetResizable(false);
damageTrackerFrame:EnableMouse(false);
damageTrackerFrame:RegisterForDrag("LeftButton")
damageTrackerFrame:SetScript("OnDragStart", damageTrackerFrame.StartMoving)
damageTrackerFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing();
    -- Save container points
    saveContainerPoints(self)
end)

damageTrackerFrame:SetResizeBounds(50, 50)
local background = damageTrackerFrame:CreateTexture("BACKGROUND")
background:SetAllPoints(damageTrackerFrame);






local function initContainer()
    local containerPoints = ProjectDMG.db.profile.containerPoints;
    damageTrackerFrame:SetWidth(containerPoints.containerWidth)
    damageTrackerFrame:SetHeight(containerPoints.containerHeight)
    damageTrackerFrame:SetPoint(containerPoints.point, UIParent, containerPoints.relativePoint, containerPoints.xOfs,
        containerPoints.yOfs)
end



function ProjectDMG:OnInitialize()
    core:Print("Welcome back " .. UnitName("player") .. "!");
    self.db = LibStub("AceDB-3.0"):New("ProjectDMGDB", defaultConfigs, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("ProjectDMG", options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ProjectDMG", "Project DMG")
    SLASH_RELOADUI1 = "/rl"; -- new slash command for reloading UI
    SlashCmdList.RELOADUI = ReloadUI;
    self:RegisterChatCommand("pdmg", "SlashCommand")
    initContainer();
    self:initDamageDisplayFramePool(damageTrackerFrame);
    options.args.spellNameToggle.disabled = self.db.profile.isHorizontal;
    self:setEditMode(nil, false);
end

function ProjectDMG:OnEnable()
    -- Called when the addon is enabled
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
    self:RegisterEvent("PLAYER_LEAVING_WORLD");
end

-- Function to update the damage data in the window
local function UpdateDamageData()
    -- -- Clear existing data
    -- scrollChild:ClearAllPoints()
    -- scrollChild:SetPoint("TOPLEFT", 0, 0)

    -- Retrieve player's damage data here (using the latest WoW APIs)
    -- Replace the placeholders with the actual code to fetch the data

    -- Iterate over the damage data and display it in the scroll frame
    local yOffset = 0;
    local xOffset = 0;
    local totalNumberOfDisplayFrames = getTotalNumberOfFrames(damageTrackerFrame);
    local startingIndex = math.max(#core.castSpells - totalNumberOfDisplayFrames + 1, 1);
    local endIndex = #core.castSpells;
    local displayFrameIndex = 1;
    local iconWidth = ProjectDMG.db.profile.isHorizontal and core.dimensions.horizontal.iconWidth or
        core.dimensions.vertical.iconWidth;
    local iconHeight = iconWidth
    while startingIndex <= endIndex do
        local frames = core.castSpells.displayFramePool[displayFrameIndex]
        if ProjectDMG.db.profile.isHorizontal then
            frames.container:SetPoint("TOPLEFT", xOffset, 0)
        else
            frames.container:SetPoint("TOPLEFT", 0, -yOffset)
        end
        frames.container:SetPoint("TOPRIGHT", damageTrackerFrame, 0, 0);
        frames.iconFrame:SetTexture(core.castSpells[startingIndex].icon);
        frames.iconFrame:SetSize(iconWidth, iconHeight);
        if ProjectDMG.db.profile.isSpellNameShown then
            frames.textFrame:SetText(core.castSpells[startingIndex].name)
            frames.textFrame:SetSize(core.dimensions.vertical.containerWidth - core.dimensions.vertical.iconWidth,
                core.dimensions.vertical.containerHeight)
        end
        startingIndex = startingIndex + 1;
        displayFrameIndex = displayFrameIndex + 1;
        if ProjectDMG.db.profile.isHorizontal then
            xOffset = xOffset + core.dimensions.horizontal.iconWidth;
        else
            yOffset = yOffset + core.dimensions.vertical.iconHeight;
        end
    end

    -- for _, damageInfo in ipairs(core.castSpells) do
    --     local damage = damageInfo.amount
    --     core:Print(damageInfo.name .. ": " .. damage)
    --     local damageText = damageTrackerFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    --     damageText:SetPoint("TOPLEFT", 10, -yOffset)
    --     damageText:SetText(damageInfo.name .. ": " .. tostring(damage))
    --     damageText:SetSize(200, 20)
    --     yOffset = yOffset + 20
    -- end

    -- Adjust the scroll frame size based on the content
    -- scrollChild:SetSize(200, yOffset)
end

local resizeButton = CreateFrame("Button", nil, damageTrackerFrame)
resizeButton:EnableMouse(false)
resizeButton:SetPoint("BOTTOMRIGHT")
resizeButton:SetSize(16, 16)
resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeButton:SetScript("OnMouseDown", function(self)
    self:GetParent():StartSizing("BOTTOMRIGHT")
end)
resizeButton:SetScript("OnMouseUp", function(self)
    self:GetParent():StopMovingOrSizing("BOTTOMRIGHT")
    saveContainerPoints(self:GetParent())
    ProjectDMG:initDamageDisplayFramePool(damageTrackerFrame)
    UpdateDamageData();
end)
resizeButton:Hide()

function ProjectDMG:COMBAT_LOG_EVENT_UNFILTERED()
    damageTrackerFrame:Show()
    local playerGUID = UnitGUID("player")
    local _, subevent, _, sourceGUID, _, _, _, _, destName = CombatLogGetCurrentEventInfo()
    local spellId, amount, critical

    if subevent == "SPELL_DAMAGE" then
        spellId, _, _, amount, _, _, _, _, _, critical = select(12, CombatLogGetCurrentEventInfo())
    end
    if sourceGUID == playerGUID and amount then
        -- core:Print("Combat log event" .. amount or "nil");
        local name, _, icon = GetSpellInfo(spellId);

        -- table.insert(core.castSpells, {
        --     spellId = spellId,
        --     amount = amount,
        --     critical = critical,
        --     name = name,
        --     icon = icon
        -- })
        -- UpdateDamageData()
    end
end

function ProjectDMG:UNIT_SPELLCAST_SUCCEEDED(event, ...)
    local unitTarget, castGUID, spellID = ...;
    local name, _, icon = GetSpellInfo(spellID);
    local spellBookName, spellSubName, _ = GetSpellBookItemName(name)
    if unitTarget == "player" and spellBookName ~= nil then
        table.insert(core.castSpells, {
            spellId = spellID,
            amount = 0,
            critical = false,
            name = name,
            icon = icon
        })
        UpdateDamageData()
    end
end

local function HandleSlashCommands(str)
    if (#str == 0) then
        -- User just entered "/at" with no additional args.
        core.commands.help();
        return;
    end

    local args = {};
    for _, arg in ipairs({ string.split(' ', str) }) do
        if (#arg > 0) then
            table.insert(args, arg);
        end
    end

    local path = core.commands; -- required for updating found table.

    for id, arg in ipairs(args) do
        if (#arg > 0) then -- if string length is greater than 0.
            arg = arg:lower();
            if (path[arg]) then
                if (type(path[arg]) == "function") then
                    -- all remaining args passed to our function!
                    path[arg](select(id + 1, unpack(args)));
                    return;
                elseif (type(path[arg]) == "table") then
                    path = path[arg]; -- another sub-table found!
                end
            else
                -- does not exist!
                core.commands.help();
                return;
            end
        end
    end
end

function ProjectDMG:SlashCommand(args)
    HandleSlashCommands(args);
end

function ProjectDMG:isSpellNameShown(info)
    return self.db.profile.isSpellNameShown
end

function ProjectDMG:setSpellNameShown(info, value)
    self.db.profile.isSpellNameShown = value
    for _, frame in ipairs(core.castSpells.displayFramePool) do
        frame.textFrame:SetShown(value)
    end
end

function ProjectDMG:isEditMode()
    return self.db.profile.isEditMode
end

function ProjectDMG:setEditMode(info, value)
    self.db.profile.isEditMode = value;
    damageTrackerFrame:SetMovable(value);
    damageTrackerFrame:EnableMouse(value);
    damageTrackerFrame:SetResizable(value);
    if value then
        background:SetColorTexture(0, 0, 0, 0.5);
        resizeButton:Show();
    else
        background:SetColorTexture(0, 0, 0, 0);
        resizeButton:Hide();
    end
end

function ProjectDMG:PLAYER_LEAVING_WORLD()
    self.setEditMode(nil, false);
end

function ProjectDMG:setHorizontal(info, value)
    self.db.profile.isHorizontal = value
    self:setSpellNameShown(nil, not value)
    options.args.spellNameToggle.disabled = value

    damageTrackerFrame:SetSize(
        core.dimensions[value and "horizontal" or "vertical"].containerWidth,
        core.dimensions[value and "horizontal" or "vertical"].containerHeight
    )
    saveContainerPoints(damageTrackerFrame);

    ProjectDMG:initDamageDisplayFramePool(damageTrackerFrame);
    UpdateDamageData();
end

function ProjectDMG:isHorizontal()
    return self.db.profile.isHorizontal
end
