-- Prevent multiple windows from opening
if getgenv().MSPaintLoaded then return end
getgenv().MSPaintLoaded = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua", true))()
local Window = Library:CreateWindow({
    Title = "mspaint", Footer = "Sniper Arena", AutoShow = true, ToggleKeybind = Enum.KeyCode.Zero,
})

--------------------------------------------------------------------------------
-- ESP TAB
--------------------------------------------------------------------------------
local ESPTab = Window:AddTab("ESP", "eye")
local MainGroup = ESPTab:AddLeftGroupbox("Visuals")

local MAX_PLAYERS = 32
local LINES_PER_PLAYER = 17
local AllLines = {}
local LineSlots = {}

for i = 1, MAX_PLAYERS * LINES_PER_PLAYER do
    AllLines[i] = Drawing.new("Line")
    AllLines[i].Visible = false
end

local slotPool = {}
for i = 1, MAX_PLAYERS do slotPool[i] = i end

local function takeSlot(plr)
    if LineSlots[plr] then return end
    local s = table.remove(slotPool, 1)
    if s then LineSlots[plr] = s end
end

local function giveSlot(plr)
    local s = LineSlots[plr]
    if s then
        LineSlots[plr] = nil
        table.insert(slotPool, s)
        local o = (s - 1) * LINES_PER_PLAYER
        for j = 1, LINES_PER_PLAYER do AllLines[o + j].Visible = false end
    end
end

local function onCharAdded(plr) giveSlot(plr) takeSlot(plr) end

local function onPlayerAdded(plr)
    if plr == LocalPlayer then return end
    takeSlot(plr)
    if plr.Character then onCharAdded(plr) end
    plr.CharacterAdded:Connect(function() onCharAdded(plr) end)
end

for _, plr in pairs(Players:GetPlayers()) do onPlayerAdded(plr) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(giveSlot)

local espEnabled = false
local renderConn

renderConn = RunService.RenderStepped:Connect(function()
    if not espEnabled then
        for i = 1, #AllLines do AllLines[i].Visible = false end
        return
    end

    local T, O = Library.Toggles, Library.Options
    local boxColor = O.ESP_BoxColor and O.ESP_BoxColor.Value or Color3.fromRGB(255, 255, 255)
    local thickness = O.ESP_Thickness and O.ESP_Thickness.Value or 1

    for i = 1, #AllLines do AllLines[i].Visible = false end

    for plr, slot in pairs(LineSlots) do
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local scale = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 2.5, 0)).Y - Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0)).Y
                local width, height = scale * 0.6, scale
                local x, y = pos.X, pos.Y
                local l, r, t, b = x - width / 2, x + width / 2, y - height / 2, y + height / 2
                local o = (slot - 1) * LINES_PER_PLAYER
                
                local lines = {{l,t,r,t}, {r,t,r,b}, {r,b,l,b}, {l,b,l,t}}
                for i=1, 4 do AllLines[o+i].Color = Color3.new(0,0,0); AllLines[o+i].Thickness = thickness+2; AllLines[o+i].From = Vector2.new(lines[i][1], lines[i][2]); AllLines[o+i].To = Vector2.new(lines[i][3], lines[i][4]); AllLines[o+i].Visible = true end
                for i=1, 4 do AllLines[o+4+i].Color = boxColor; AllLines[o+4+i].Thickness = thickness; AllLines[o+4+i].From = Vector2.new(lines[i][1], lines[i][2]); AllLines[o+4+i].To = Vector2.new(lines[i][3], lines[i][4]); AllLines[o+4+i].Visible = true end
            end
        end
    end
end)

MainGroup:AddToggle("ESP_Enabled", { Text = "Bounding Box ESP", Default = false, Callback = function(v) espEnabled = v end })
local ESPOptions = ESPTab:AddRightGroupbox("Options")
ESPOptions:AddSlider("ESP_Thickness", { Text = "Outline Thickness", Default = 1, Min = 1, Max = 6 })
ESPOptions:AddLabel("Box Color"):AddColorPicker("ESP_BoxColor", { Default = Color3.fromRGB(255, 255, 255) })

--------------------------------------------------------------------------------
-- COMBAT TAB
--------------------------------------------------------------------------------
local CombatTab = Window:AddTab("Combat", "swords")
local AimbotGroup = CombatTab:AddLeftGroupbox("Aimbot")
local HitboxGroup = CombatTab:AddLeftGroupbox("Hitbox Expander")

local aimbotEnabled = false
AimbotGroup:AddToggle("Aimbot_Enabled", { Text = "Enable Aimbot", Default = false, Callback = function(v) aimbotEnabled = v end })

local hitboxEnabled = false local hitboxSize = 15
local function resetHitboxes() for _, p in pairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then p.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1) end end end
HitboxGroup:AddToggle("Hitbox_Enabled", { Text = "Enable Hitboxes", Default = false, Callback = function(v) hitboxEnabled = v if not v then resetHitboxes() end end })
HitboxGroup:AddSlider("Hitbox_Size", { Text = "Hitbox Size", Default = 15, Min = 2, Max = 50, Callback = function(v) hitboxSize = v end })

RunService.RenderStepped:Connect(function()
    if hitboxEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                p.Character.HumanoidRootPart.Transparency = 1
                p.Character.HumanoidRootPart.CanCollide = false
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- CONFIG & TELEPORT
--------------------------------------------------------------------------------
local ConfigFile = "mspaint_" .. LocalPlayer.Name .. ".json"
local function SaveConfig() if writefile then local d = {Toggles={}, Options={}} for n,v in pairs(Library.Toggles) do d.Toggles[n]=v.Value end for n,v in pairs(Library.Options) do d.Options[n]=v.Value end writefile(ConfigFile, HttpService:JSONEncode(d)) end end
local function LoadConfig() if readfile and isfile(ConfigFile) then local d = HttpService:JSONDecode(readfile(ConfigFile)) if d.Toggles then for n,v in pairs(d.Toggles) do if Library.Toggles[n] then Library.Toggles[n]:SetValue(v) end end end end end

local ConfigTab = Window:AddTab("Config", "file-text")
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Save Settings", Func=SaveConfig})
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Load Settings", Func=LoadConfig})

local queue_func = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
if queue_func then
    queue_func([[
        if not getgenv().MSPaintLoaded then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/sniper.lua"))()
        end
    ]])
end

LocalPlayer.OnTeleport:Connect(SaveConfig)
task.delay(1, LoadConfig)
