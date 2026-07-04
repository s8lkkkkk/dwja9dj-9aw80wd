-- Singleton Check: Prevents multiple windows
if getgenv().MSPaintLoaded then return end
getgenv().MSPaintLoaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua", true))()
local Window = Library:CreateWindow({
    Title = "mspaint", Footer = "Sniper Arena", AutoShow = true, ToggleKeybind = Enum.KeyCode.Zero,
})

--------------------------------------------------------------------------------
-- UI COMPONENTS (Define these before loading config)
--------------------------------------------------------------------------------
local ESPTab = Window:AddTab("ESP", "eye")
local MainGroup = ESPTab:AddLeftGroupbox("Visuals")
MainGroup:AddToggle("ESP_Enabled", { Text = "Bounding Box ESP", Default = false })
MainGroup:AddToggle("ESP_CornerBox", { Text = "Corner Box", Default = false })
MainGroup:AddToggle("ESP_Tracers", { Text = "Tracers", Default = false })

local ESPOptions = ESPTab:AddRightGroupbox("Options")
ESPOptions:AddSlider("ESP_Thickness", { Text = "Outline Thickness", Default = 1, Min = 1, Max = 6 })
ESPOptions:AddLabel("Box Color"):AddColorPicker("ESP_BoxColor", { Default = Color3.fromRGB(255, 255, 255) })
ESPOptions:AddLabel("Tracer Color"):AddColorPicker("ESP_TracerColor", { Default = Color3.fromRGB(255, 0, 0) })

local CombatTab = Window:AddTab("Combat", "swords")
local HitboxGroup = CombatTab:AddLeftGroupbox("Hitbox Expander")
HitboxGroup:AddToggle("Hitbox_Enabled", { Text = "Enable Hitboxes", Default = false })
HitboxGroup:AddSlider("Hitbox_Size", { Text = "Hitbox Size", Default = 15, Min = 2, Max = 50 })

--------------------------------------------------------------------------------
-- CONFIGURATION SYSTEM
--------------------------------------------------------------------------------
local ConfigFile = "mspaint_" .. LocalPlayer.Name .. ".json"

local function SaveConfig()
    if not writefile then return end
    local data = { Toggles = {}, Options = {} }
    for n, v in pairs(Library.Toggles) do data.Toggles[n] = v.Value end
    for n, v in pairs(Library.Options) do 
        if typeof(v.Value) == "Color3" then data.Options[n] = {v.Value.R, v.Value.G, v.Value.B}
        else data.Options[n] = v.Value end
    end
    writefile(ConfigFile, HttpService:JSONEncode(data))
end

local function LoadConfig()
    if not (readfile and isfile and isfile(ConfigFile)) then return end
    local success, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end)
    if not success then return end
    
    if data.Toggles then for n, v in pairs(data.Toggles) do if Library.Toggles[n] then Library.Toggles[n]:SetValue(v) end end end
    if data.Options then for n, v in pairs(data.Options) do if Library.Options[n] then 
        if type(v) == "table" then Library.Options[n]:SetValueRGB(Color3.new(v[1], v[2], v[3])) 
        else Library.Options[n]:SetValue(v) end end end end
end

local ConfigTab = Window:AddTab("Config", "file-text")
local ManageGroup = ConfigTab:AddLeftGroupbox("Management")
ManageGroup:AddButton({Text="Save Settings", Func=SaveConfig})
ManageGroup:AddButton({Text="Load Settings", Func=LoadConfig})

-- Auto-load on startup
task.spawn(LoadConfig)

-- Teleport Queue
local queue_func = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
if queue_func then 
    queue_func([[loadstring(game:HttpGet("https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/sniper.lua"))()]]) 
end
LocalPlayer.OnTeleport:Connect(SaveConfig)
