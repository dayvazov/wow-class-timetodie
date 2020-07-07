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
            set = "SetVisible"
        },
        interval = {
            type = "input",
            name = "Update Interval",
            desc = "The update interval for the time to die timers",
            usage = "<update interval>",
            get = "GetUpdateInterval",
            set = "SetUpdateInterval"
        }
    }
}

local initial_estimate = 5 * 60

local LogLevel = 1
local DefaultLogLevel = 1
function TimeToDie:Log(msg, level)
	if level > LogLevel then
		print(msg)
	end
end

-- speed optimizations (mostly so update functions are faster)
function SecondsToClock(seconds)
    local seconds = tonumber(seconds)

    hours = string.format("%02.f", floor(seconds / 3600));
    mins = string.format("%02.f", floor(seconds / 60 - (hours * 60)));
    secs = string.format("%02.f", floor(seconds - hours * 3600 - mins * 60));

    return hours .. ":" .. mins .. ":" .. secs
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

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
    TimeToDie.previousUnits = {}
    TimeToDie.units = {}
    TimeToDie.isVisible = false
    TimeToDie.timerUpdateInterval = 0.5
    TimeToDie.timerCount = 0
    TimeToDie.isInCombat = false

    local info = AceGUI:Create("Window")
    info:Hide()
    info:SetWidth(400)
    info:SetHeight(200)
    info:SetLayout("Fill")
    info:SetAutoAdjustHeight(true)
    info.frame:SetMinResize(100, 100)

    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("Flow")
    info:AddChild(scroll)

    local text = AceGUI:Create("Label")
    text:SetWidth(300)
    scroll:AddChild(text)

    self.infoFrame = info 
    self.textFrame = text

    LibStub("AceConfig-3.0"):RegisterOptionsTable(self.addonName, options, {
        "timetodie",
        "ttd"
    })

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

function TimeToDie:UNIT_HEALTH(event, UnitId)
    self:UpdateUnit(UnitId)
end

function TimeToDie:PLAYER_REGEN_DISABLED()
    -- We've entered combat, so lets clear the log.
    self:Print("Entering combat, tracking time to die.")
    self.isInCombat = true
    self.units = {}
    self.previousUnits = {}
end

function TimeToDie:PLAYER_REGEN_ENABLED()
    -- We've exited combat, lets capture actual times on all our entries.

    self:Print("Exiting combat, actuals being recorded.")
    self:PrintUnits()

    self.isInCombat = false
end

function TimeToDie:EnableUpdateLoop(elapsed)
    self.infoFrame.frame:SetScript("OnUpdate", function(self, elapsed)
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
    local text = ""

    for _, unit in pairs(self.units) do
        unit.timeLeft = unit.timeLeft - self.timerCount

        if unit.timeLeft < 0 then
            unit.timeLeft = 0
        end
         
        text = 
            text .. 
            string.format("%s - %s", SecondsToClock(unit.timeLeft), unit.name) ..
            string.format(" (%s)\n", SecondsToClock(unit.time - unit.timeStart))
    end

    self.textFrame:SetText(text)
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

function TimeToDie:UpdateUnit(unit)
    if not unit then
        return
    end

    local time = GetTime()
    local guid = UnitGUID(unit)

    if not guid then
        return
    end

    if self.units ~= {} then
        table.insert(self.previousUnits, self:Copy(self.units))
    end

    if self.units[guid] == nil then
        self.units[guid] = {
            timeStart = GetServerTime()
        }
    end

    self:UpdateUnitInstance(self.units[guid], unit)
    self:UpdateTimeLeft(self.units[guid], self.previousUnits[#(self.previousUnits)][guid])
end

function TimeToDie:UpdateUnitInstance(instance, unit)
    instance.name = UnitName(unit)
    instance.level = UnitLevel(unit)
    instance.health = UnitHealth(unit)
    instance.health_max = UnitHealthMax(unit)
    instance.armor = UnitArmor(unit)
    instance.guid = UnitGUID(unit)
    instance.time = GetServerTime()
    instance.timeLeft = 5 * 60
end

function TimeToDie:UpdateTimeLeft(unit, previousUnit)
    if not previousUnit then
        return
    end

    local dt = unit.time - previousUnit.time
    local dh = previousUnit.health - unit.health
    local timeLeft = unit.health * (dt / dh)

    if abs(unit.timeLeft - timeLeft) > self.timerUpdateInterval then
        unit.timeLeft = timeLeft
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

function TimeToDie:PrintUnits()
    for k, _ in pairs(self.units) do
        self:PrintUnit(k)
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
