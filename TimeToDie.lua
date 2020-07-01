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
    LibStub("AceConfig-3.0"):RegisterOptionsTable("TimeToDie", options, {"timetodie", "ttd"})
end

function TimeToDie:OnEnable()
    self:Print("Hello World!")
    self:RegisterEvent("UNIT_HEALTH")
    
    local frame = AceGUI:Create("Frame")
    frame:SetTitle("Example Frame")
    frame:SetStatusText("AceGUI-3.0 Example Container Frame")
end

function TimeToDie:OnDisable()
    -- Called when the addon is disabled
end

function TimeToDie:UNIT_HEALTH()

    self:Print("Health Changed")
end

function TimeToDie:PLAYER()
    self:Print("I'm the player!")
end
