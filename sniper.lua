-- Prevent multiple windows from opening
if getgenv().MSPaintLoaded then return end
getgenv().MSPaintLoaded = true

-- Setup Globals for Turboguru logic
_G.HeadSize = 15
_G.Disabled = false 

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
-- ESP TAB (Full Logic)
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

local function takeSlot(plr) if LineSlots[plr] then return end local s = table.remove(slotPool, 1) if s then LineSlots[plr] = s end end
local function giveSlot(plr) local s = LineSlots[plr] if s then LineSlots[plr] = nil table.insert(slotPool, s) local o = (s-1)*LINES_PER_PLAYER for j=1,LINES_PER_PLAYER do AllLines[o+j].Visible = false end end end
local function onCharAdded(plr) giveSlot(plr) takeSlot(plr) end
local function onPlayerAdded(plr) if plr == LocalPlayer then return end takeSlot(plr) if plr.Character then onCharAdded(plr) end plr.CharacterAdded:Connect(function() onCharAdded(plr) end) end
for _, plr in pairs(Players:GetPlayers()) do onPlayerAdded(plr) end
Players.PlayerAdded:Connect(onPlayerAdded) Players.PlayerRemoving:Connect(giveSlot)

RunService.RenderStepped:Connect(function()
    if not Library.Toggles.ESP_Enabled.Value then for i=1, #AllLines do AllLines[i].Visible = false end return end
    local boxColor = Library.Options.ESP_BoxColor.Value
    local tracerColor = Library.Options.ESP_TracerColor.Value
    local thickness = Library.Options.ESP_Thickness.Value
    
    for i=1, #AllLines do AllLines[i].Visible = false end

    for plr, slot in pairs(LineSlots) do
        local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local scale = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 2.5, 0)).Y - Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2.5, 0)).Y
                local w, h = scale * 0.6, scale
                local x, y = pos.X, pos.Y
                local l, r, t, b = x-w/2, x+w/2, y-h/2, y+h/2
                local o = (slot-1)*LINES_PER_PLAYER
                
                if Library.Toggles.ESP_CornerBox.Value then
                    local cw, ch = w*0.25, h*0.25
                    local lines = {{l,t,l+cw,t}, {l,t,l,t+ch}, {r,t,r-cw,t}, {r,t,r,t+ch}, {r,b,r-cw,b}, {r,b,r,b-ch}, {l,b,l+cw,b}, {l,b,l,b-ch}}
                    for i=1, 8 do AllLines[o+i].Color = Color3.new(0,0,0); AllLines[o+i].Thickness = thickness+2; AllLines[o+i].From = Vector2.new(lines[i][1], lines[i][2]); AllLines[o+i].To = Vector2.new(lines[i][3], lines[i][4]); AllLines[o+i].Visible = true end
                    for i=1, 8 do AllLines[o+8+i].Color = boxColor; AllLines[o+8+i].Thickness = thickness; AllLines[o+8+i].From = Vector2.new(lines[i][1], lines[i][2]); AllLines[o+8+i].To = Vector2.new(lines[i][3], lines[i][4]); AllLines[o+8+i].Visible = true end
                else
                    local lines = {{l,t,r,t}, {r,t,r,b}, {r,b,l,b}, {l,b,l,t}}
                    for i=1, 4 do AllLines[o+i].Color = Color3.new(0,0,0); AllLines[o+i].Thickness = thickness+2; AllLines[o+i].From = Vector2.new(lines[i][1], lines[i][2]); AllLines[o+i].To = Vector2.new(lines[i][3], lines[i][4]); AllLines[o+i].Visible = true end
                    for i=1, 4 do AllLines[o+4+i].Color = boxColor; AllLines[o+4+i].Thickness = thickness; AllLines[o+4+i].From = Vector2.new(lines[i][1], lines[i][2]); AllLines[o+4+i].To = Vector2.new(lines[i][3], lines[i][4]); AllLines[o+4+i].Visible = true end
                end
                if Library.Toggles.ESP_Tracers.Value then AllLines[o+17].Color = tracerColor; AllLines[o+17].Thickness = thickness; AllLines[o+17].From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); AllLines[o+17].To = Vector2.new(x, y+h/2); AllLines[o+17].Visible = true end
            end
        end
    end
end)

MainGroup:AddToggle("ESP_Enabled", {Text="Bounding Box ESP", Default=false})
MainGroup:AddToggle("ESP_CornerBox", {Text="Corner Box", Default=false})
MainGroup:AddToggle("ESP_Tracers", {Text="Tracers", Default=false})
local ESPOptions = ESPTab:AddRightGroupbox("Options")
ESPOptions:AddSlider("ESP_Thickness", {Text="Outline Thickness", Default=1, Min=1, Max=6})
ESPOptions:AddLabel("Box Color"):AddColorPicker("ESP_BoxColor", {Default=Color3.fromRGB(255, 255, 255)})
ESPOptions:AddLabel("Tracer Color"):AddColorPicker("ESP_TracerColor", {Default=Color3.fromRGB(255, 0, 0)})

--------------------------------------------------------------------------------
-- COMBAT TAB
--------------------------------------------------------------------------------
local CombatTab = Window:AddTab("Combat", "swords")
local HitboxGroup = CombatTab:AddLeftGroupbox("Hitbox Expander")
HitboxGroup:AddToggle("Hitbox_Enabled", {Text="Enable Hitboxes", Default=false, Callback = function(v) _G.Disabled = v end})
HitboxGroup:AddSlider("Hitbox_Size", {Text="Hitbox Size", Default=15, Min=2, Max=50, Callback = function(v) _G.HeadSize = v end})

RunService.RenderStepped:Connect(function()
    if _G.Disabled then
        for _, v in next, Players:GetPlayers() do
            if v.Name ~= LocalPlayer.Name and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    v.Character.HumanoidRootPart.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize)
                    v.Character.HumanoidRootPart.Transparency = 1
                    v.Character.HumanoidRootPart.CanCollide = false
                end)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- CONFIG & TELEPORT
--------------------------------------------------------------------------------
local ConfigFile = "mspaint_" .. LocalPlayer.Name .. ".json"
local function SaveConfig() 
    if not writefile then return end
    local d = {Toggles={}, Options={}} 
    for n,v in pairs(Library.Toggles) do d.Toggles[n]=v.Value end 
    for n,v in pairs(Library.Options) do 
        if typeof(v.Value) == "Color3" then d.Options[n]={v.Value.R, v.Value.G, v.Value.B} else d.Options[n]=v.Value end
    end 
    writefile(ConfigFile, HttpService:JSONEncode(d)) 
end

local function LoadConfig() 
    if not (readfile and isfile and isfile(ConfigFile)) then return end 
    local d = HttpService:JSONDecode(readfile(ConfigFile)) 
    if d.Toggles then for n,v in pairs(d.Toggles) do if Library.Toggles[n] then Library.Toggles[n]:SetValue(v) end end end
    if d.Options then for n,v in pairs(d.Options) do if Library.Options[n] then 
        if type(v) == "table" then Library.Options[n]:SetValueRGB(Color3.new(v[1], v[2], v[3])) else Library.Options[n]:SetValue(v) end 
    end end end
end

local ConfigTab = Window:AddTab("Config", "file-text")
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Save Settings", Func=SaveConfig})
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Load Settings", Func=LoadConfig})

local queue_func = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
if queue_func then queue_func([[if not getgenv().MSPaintLoaded then loadstring(game:HttpGet("https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/sniper.lua"))() end]]) end
LocalPlayer.OnTeleport:Connect(SaveConfig)
task.delay(1, LoadConfig)
