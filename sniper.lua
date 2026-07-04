-- Singleton Check: Prevents multiple windows
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
RunService.RenderStepped:Connect(function()
    if not espEnabled then
        for i = 1, #AllLines do AllLines[i].Visible = false end
        return
    end

    local T, O = Library.Toggles, Library.Options
    local boxColor = O.ESP_BoxColor.Value
    local tracerColor = O.ESP_TracerColor.Value
    local thickness = O.ESP_Thickness.Value
    local cornerBox = T.ESP_CornerBox.Value
    local tracers = T.ESP_Tracers.Value

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
                
                if cornerBox then
                    local cw, ch = width * 0.25, height * 0.25
                    local lines = {{l,t,l+cw,t}, {l,t,l,t+ch}, {r,t,r-cw,t}, {r,t,r,t+ch}, {r,b,r-cw,b}, {r,b,r,b-ch}, {l,b,l+cw,b}, {l,b,l,b-ch}}
                    for i=1, 8 do AllLines[o+i].Color = Color3.new(0,0,0); AllLines[o+i].Thickness = thickness+2; AllLines[o+i].From = Vector2.new(lines[i][1], lines[i][2]); AllLines[o+i].To = Vector2.new(lines[i][3], lines[i][4]); AllLines[o+i].Visible = true end
                    for i=1, 8 do AllLines[o+8+i].Color = boxColor; AllLines[o+8+i].Thickness = thickness; AllLines[o+8+i].From = Vector2.new(lines[i][1], lines[i][2]); AllLines[o+8+i].To = Vector2.new(lines[i][3], lines[i][4]); AllLines[o+8+i].Visible = true end
                else
                    local lines = {{l,t,r,t}, {r,t,r,b}, {r,b,l,b}, {l,b,l,t}}
                    for i=1, 4 do AllLines[o+i].Color = Color3.new(0,0,0); AllLines[o+i].Thickness = thickness+2; AllLines[o+i].From = Vector2.new(lines[i][1], lines[i][2]); AllLines[o+i].To = Vector2.new(lines[i][3], lines[i][4]); AllLines[o+i].Visible = true end
                    for i=1, 4 do AllLines[o+4+i].Color = boxColor; AllLines[o+4+i].Thickness = thickness; AllLines[o+4+i].From = Vector2.new(lines[i][1], lines[i][2]); AllLines[o+4+i].To = Vector2.new(lines[i][3], lines[i][4]); AllLines[o+4+i].Visible = true end
                end
                if tracers then
                    AllLines[o+17].Color = tracerColor; AllLines[o+17].Thickness = thickness; AllLines[o+17].From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); AllLines[o+17].To = Vector2.new(x, y+height/2); AllLines[o+17].Visible = true
                end
            end
        end
    end
end)

MainGroup:AddToggle("ESP_Enabled", { Text = "Bounding Box ESP", Default = false, Callback = function(v) espEnabled = v end })
MainGroup:AddToggle("ESP_CornerBox", { Text = "Corner Box", Default = false })
MainGroup:AddToggle("ESP_Tracers", { Text = "Tracers", Default = false })
local ESPOptions = ESPTab:AddRightGroupbox("Options")
ESPOptions:AddSlider("ESP_Thickness", { Text = "Outline Thickness", Default = 1, Min = 1, Max = 6 })
ESPOptions:AddLabel("Box Color"):AddColorPicker("ESP_BoxColor", { Default = Color3.fromRGB(255, 255, 255) })
ESPOptions:AddLabel("Tracer Color"):AddColorPicker("ESP_TracerColor", { Default = Color3.fromRGB(255, 0, 0) })

--------------------------------------------------------------------------------
-- COMBAT TAB
--------------------------------------------------------------------------------
local CombatTab = Window:AddTab("Combat", "swords")
local HitboxGroup = CombatTab:AddLeftGroupbox("Hitbox Expander")
local hitboxEnabled, hitboxSize = false, 15
HitboxGroup:AddToggle("Hitbox_Enabled", { Text = "Enable Hitboxes", Default = false, Callback = function(v) hitboxEnabled = v end })
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
local ConfigTab = Window:AddTab("Config", "file-text")
local ConfigFile = "mspaint_" .. LocalPlayer.Name .. ".json"
local function SaveConfig() if writefile then local d = {Toggles={}, Options={}} for n,v in pairs(Library.Toggles) do d.Toggles[n]=v.Value end for n,v in pairs(Library.Options) do d.Options[n]=v.Value end writefile(ConfigFile, HttpService:JSONEncode(d)) end end
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Save Settings", Func=SaveConfig})

local queue_func = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
if queue_func then queue_func([[loadstring(game:HttpGet("https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/sniper.lua"))()]]) end
LocalPlayer.OnTeleport:Connect(SaveConfig)
