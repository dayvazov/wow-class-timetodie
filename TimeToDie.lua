TimeToDie = LibStub("AceAddon-3.0"):NewAddon("TimeToDie", "AceConsole-3.0", "AceEvent-3.0")
AceGUI = LibStub("AceGUI-3.0")

local options = {
    name = "Time to Die",
    handler = TimeToDie,
    type = 'group',
    args = {
        show = {
            type = "toggle",
            name = " Is Time To Die Visible",
            desc = "Toggle visibility of the main time to death",
            get = "GetVisible",
            set = "SetVisible",
        },
        interval = {
            type = "input",
            name = "Update Interval",
            desc = "The update interval for the time to die timers",
            usage = "<update interval>",
            get = "GetUpdateInterval",
            set = "SetUpdateInterval"
        },
    },
}

-- speed optimizations (mostly so update functions are faster)

local _G = getfenv(0);
local abs = _G.abs;
local min = _G.min;
local floor = _G.floor;
local mod = _G.mod;
local GetServerTime = _G.GetServerTime;

function TimeToDie:OnInitialize()
    -- Called when the addon is loaded
    TimeToDie.addonName = "TimeToDie"
    TimeToDie.commandName = "ttd"
    TimeToDie.commandNameLong = "timetodie"
    TimeToDie.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(self.addonName, self.addonName)
    TimeToDie.previousUnits = { }
    TimeToDie.units = { }
    TimeToDie.isVisible = false
    TimeToDie.timerUpdateInterval = 0.5
    TimeToDie.timerCount = 0
    TimeToDie.isInCombat = false

    self.infoFrame = AceGUI:Create("Window")
    self.infoFrame:Hide()
    self.infoFrame:SetWidth(400)
    self.infoFrame:SetHeight(200)
    self.infoFrame:SetLayout("List")
    self.infoFrame:SetAutoAdjustHeight(true)
    self.infoFrame.frame:SetMinResize(100, 100)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.addonName, options, {"timetodie", "ttd"})

    self:RegisterChatCommand(self.commandNameLong, "ChatCommand")
    self:RegisterChatCommand(self.commandName, "ChatCommand")
end

function TimeToDie:OnEnable()
    self:Print("You will know when it is time to die!")
    self:RegisterEvent("UNIT_HEALTH")
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:EnableUpdateLoop()
    
end

function TimeToDie:EnableUpdateLoop(elapsed)
    self.infoFrame.frame:SetScript("OnUpdate", function (self, elapsed)
        TimeToDie.timerCount = TimeToDie.timerCount + elapsed 

        -- if we're not in combat and the update time has not elapsed, don't update
        if not TimeToDie.isInCombat or TimeToDie.timerCount < TimeToDie.timerUpdateInterval then
            return
        end

        TimeToDie:UpdateTimers()
        TimeToDie.timerCount = 0
    end)
end

function TimeToDie:UpdateTimers()
    for _, unit in pairs(self.units) do
        unit.timeLeft = unit.timeLeft - self.timerCount

        self:UpdateLabel(unit.label, unit)
    end
end

function TimeToDie:UNIT_HEALTH(event, unitTarget)
    self:UpdateUnit(unitTarget)
end

function TimeToDie:PLAYER_REGEN_DISABLED()
    -- We've entered combat, so lets clear the log.
    self:Print("Entering combat, tracking time to die.")
    self.isInCombat = true
end

function TimeToDie:PLAYER_REGEN_ENABLED()
    -- We've exited combat, lets capture actual times on all our entries.
    self.Print("Exiting combat, actuals being recorded.")
    self.isInCombat = false
end

function TimeToDie:OnDisable()
    -- Called when the addon is disabled
    self:SetVisible(false)
end

function TimeToDie:ChatCommand(input)
    if not input or input:trim() == "" then
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    else
        LibStub("AceConfigCmd-3.0"):HandleCommand(self.commandName, self.addonName, input)
    end
end

function TimeToDie:GetVisible(info)
    return self.isVisible
end

function TimeToDie:SetVisible(info, value)
    self.isVisible = value

    if self.isVisible then
        self.infoFrame:Show()
    else
        self.infoFrame:Hide()
    end
end

function TimeToDie:GetUpdateInterval(info)
    return self.timerUpdateInterval
end

function TimeToDie:SetUpdateInterval(info, value)
    local interval = tonumber(value)
    if interval then
        self.timerUpdateInterval = interval
    else
        self.timerUpdateInterval = 0.5
    end
end

function TimeToDie:UpdateLabel(label, unit)
    if not label or not unit then
        return
    end

    label:SetText(string.format("%s TTD: %s", unit.name, SecondsToClock(unit.timeLeft)))
end

function SecondsToClock(seconds)
    local seconds = tonumber(seconds)
  
    hours = string.format("%02.f", floor(seconds/3600));
    mins = string.format("%02.f", floor(seconds/60 - (hours*60)));
    secs = string.format("%02.f", floor(seconds - hours*3600 - mins *60));

    return hours..":"..mins..":"..secs
  end

function TimeToDie:UpdateUnit(unit)
    if not unit then
        return
    end

    local time = GetTime() 
    local guid = UnitGUID(unit)

    if not guid then
        return
    end

    if self.units ~= { } then
        table.insert(self.previousUnits, self:Copy(self.units))
    end

    if self.units[guid] == nil then
        self.units[guid] = { 
            label = AceGUI:Create("Label")
        }
        
        self.infoFrame:AddChild(self.units[guid].label)
    end

    self.units[guid].name = UnitName(unit)
    self.units[guid].level = UnitLevel(unit)
    self.units[guid].health = UnitHealth(unit)
    self.units[guid].health_max = UnitHealthMax(unit)
    self.units[guid].armor = UnitArmor(unit)
    self.units[guid].guid = UnitGUID(unit)
    self.units[guid].time = GetServerTime()
    self.units[guid].timeLeft = 5 * 60

    if self.previousUnits[#(self.previousUnits)][guid] then
        local dt = self.units[guid].time - self.previousUnits[#(self.previousUnits)][guid].time
        local dh = self.previousUnits[#(self.previousUnits)][guid].health - self.units[guid].health
        local pTimeLeft = self.units[guid].health * (dt/dh)

        if abs(self.units[guid].timeLeft - pTimeLeft) > self.timerUpdateInterval then
            self.units[guid].timeLeft = pTimeLeft
        end
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
