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
    TimeToDie.previousUnits = { }
    TimeToDie.units = { }

    self.infoFrame = AceGUI:Create("Frame")
    self.infoFrame:Hide()
    self.infoFrame:SetWidth(200)
    self.infoFrame:SetHeight(200)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.addonName, options, {"timetodie", "ttd"})

    self:RegisterChatCommand(self.commandNameLong, "ChatCommand")
    self:RegisterChatCommand(self.commandName, "ChatCommand")
end

function TimeToDie:OnEnable()
    self:Print("Hello World!")
    self:RegisterEvent("UNIT_HEALTH")
    self.infoFrame:Show()
    self.infoFrame:SetLayout("List")
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
    self:UpdateUnit(unitTarget)
end

function TimeToDie:CreateLabel()
end

function TimeToDie:UpdateLabel(label, unit)
    if not label or not unit then
        return
    end

    label:SetText(string.format("%s TTD: %s", unit.name, SecondsToClock(unit.time_left)))
end

function SecondsToClock(seconds)
    local seconds = tonumber(seconds)
  
    -- if seconds <= 0 then
    --   return "00:00:00";
    -- else
      hours = string.format("%02.f", math.floor(seconds/3600));
      mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
      secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
      return hours..":"..mins..":"..secs
    -- end
  end

function TimeToDie:UpdateUnit(unit)
    self:Print("Trying to Update Unit")
    
    if not unit then
        return
    end

    local time = GetTime() 
    local guid = UnitGUID(unit)

    table.insert(self.previousUnits, 0, self:Copy(self.units))

    if self.units[guid] == nil then
        self.units[guid] = {}
        self.units[guid].label = AceGUI:Create("Label")
        self.infoFrame:AddChild(self.units[guid].label)
    end

    self.units[guid].name = UnitName(unit)
    self.units[guid].level = UnitLevel(unit)
    self.units[guid].health = UnitHealth(unit)
    self.units[guid].health_max = UnitHealthMax(unit)
    self.units[guid].armor = UnitArmor(unit)
    self.units[guid].guid = UnitGUID(unit)
    self.units[guid].time = GetTime()

    if self.previousUnits[0][guid] then
        dt = self.units[guid].time - self.previousUnits[0][guid].time
        dh = self.previousUnits[0][guid].health - self.units[guid].health 

        self.units[guid].time_left = self.units[guid].health * (dt/dh)
        self:UpdateLabel(self.units[guid].label, self.units[guid])
    end
end

function TimeToDie:Copy(units)
    if not units then
        return nil
    end

    local units_copy = {}

    for k, v in pairs(units) do
        local unit = {}
        
        for unit_k, unit_v in pairs(v) do
            if unit_k ~= "label" then
                unit[unit_k] = unit_v
            end
        end

        units_copy[k] = unit
    end

    return units_copy
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
