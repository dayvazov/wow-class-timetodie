TimeToDie = LibStub("AceAddon-3.0"):NewAddon("TimeToDie", "AceConsole-3.0", "AceEvent-3.0")
AceGUI = LibStub("AceGUI-3.0")

local options = {
    name = "TimeToDie",
    handler = TimeToDie,
    type = 'group',
    args = {

    },
}

function TimeToDie:OnInitialize()
    -- Called when the addon is loaded
    TimeToDie.addonName = "TimeToDie"
    TimeToDie.commandName = "ttd"
    TimeToDie.commandNameLong = "timetodie"
    TimeToDie.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.addonName, self.addonName)
    TimeToDie.units = { }

    self.infoFrame = AceGUI:Create("Frame")
    self.infoFrame:Hide()

    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.addonName, options, {"timetodie", "ttd"})

    self:RegisterChatCommand(self.commandNameLong, "ChatCommand")
    self:RegisterChatCommand(self.commandName, "ChatCommand")
end

function TimeToDie:OnEnable()
    self:Print("Hello World!")
    self:RegisterEvent("UNIT_HEALTH")
    self.infoFrame:Show()
    self.infoFrame:SetLayout("List")
    
    local label = AceGUI:Create("Label")
    label:SetText("Player Health: N/A")
    local label = AceGUI:Create("Label")
    label:SetText("Player Health: N/A")

    self.infoFrame:AddChild(label)
end

function TimeToDie:OnDisable()
    -- Called when the addon is disabled
end

function TimeToDie:ChatCommand(input)
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    else
        LibStub("AceConfigCmd-3.0"):HandleCommand(self.commandName, self.addonName, input)
    end
end

function TimeToDie:UNIT_HEALTH(event, unitTarget)
    self:Print(event, unitTarget)
    self:UpdateUnit(unitTarget)
    -- self:Print(string.format("Health Changed %s", name))
end

function TimeToDie:PLAYER()
    self:Print("I'm the player!")
end

function TimeToDie:UpdateUnit(unit)
    self:Print("Trying to Update Unit")
    
    if not unit then
        return
    end
    
    self:Print("Updating Unit")
    
    local guid = UnitGUID(unit)
    local unit = {
        name = UnitName(unit),
        level = UnitLevel(unit),
        health = UnitHealth(unit),
        health_max = UnitHealthMax(unit),
        armor = UnitArmor(unit),
        guid = UnitGUID(unit)
    }

    self:PrintUnit(unit.guid)
    if self.units[guid] ~= nil then
        self.units[guid] = unit

        self:Print("Existing unit")
    else
        self.units[guid] = unit
        self:Print("New unit")
        
        self:Print("But update time to death")
    end 
end

function TimeToDie:PrintUnit(guid)
    if self.units[guid] == nil then
        self:Print("Unit not found.")
        return
    end

    for k, v in pairs(self.units[guid]) do
        self:Print(k, v)
    end
end
