-- Prevent multiple windows
if getgenv().MSPaintLoaded then return end
getgenv().MSPaintLoaded = true

-- Setup Globals
_G.HeadSize = 15
_G.Disabled = false 

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua", true))()
local Window = Library:CreateWindow({Title = "mspaint", Footer = "Sniper Arena", AutoShow = true, ToggleKeybind = Enum.KeyCode.Zero})

--------------------------------------------------------------------------------
-- HUD & SERVER STATUS
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local StatusFrame = Instance.new("Frame", ScreenGui)
StatusFrame.Size = UDim2.new(0, 180, 0, 80)
StatusFrame.Position = UDim2.new(0, 10, 0, 10)
StatusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
StatusFrame.BorderSizePixel = 0
local StatusText = Instance.new("TextLabel", StatusFrame)
StatusText.Size = UDim2.new(1, -10, 1, 0)
StatusText.Position = UDim2.new(0, 10, 0, 0)
StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusText.BackgroundTransparency = 1
StatusText.TextXAlignment = Enum.TextXAlignment.Left

RunService.RenderStepped:Connect(function()
    StatusText.Text = string.format("FPS: %d | Ping: %dms\nPlayers: %d", workspace:GetRealPhysicsFPS(), game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue(), #Players:GetPlayers())
end)

--------------------------------------------------------------------------------
-- ESP, TRACERS, SILENT AIM & FOV
--------------------------------------------------------------------------------
local ESPTab = Window:AddTab("ESP", "eye")
local MainGroup = ESPTab:AddLeftGroupbox("Visuals")
local SilentGroup = ESPTab:AddRightGroupbox("Combat Assist")

local AllLines = {} for i=1, 128 do AllLines[i] = Drawing.new("Line"); AllLines[i].Visible = false end
local FOVCircle = Drawing.new("Circle") FOVCircle.Thickness = 1 FOVCircle.Filled = false FOVCircle.Color = Color3.new(1,1,1)

SilentGroup:AddToggle("SilentAim_Enabled", {Text = "Enable Silent Aim"})
SilentGroup:AddToggle("FOV_Visible", {Text = "Show FOV Circle"})
SilentGroup:AddSlider("FOV_Radius", {Text = "FOV Radius", Default = 100, Min = 20, Max = 500})
SilentGroup:AddLabel("FOV Color"):AddColorPicker("FOV_Color", {Default = Color3.fromRGB(255, 255, 255)})

local SilentAimTarget = nil

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = Library.Options.FOV_Radius.Value
    FOVCircle.Visible = Library.Toggles.FOV_Visible.Value
    FOVCircle.Color = Library.Options.FOV_Color.Value
    
    SilentAimTarget = nil
    if Library.Toggles.SilentAim_Enabled.Value then
        local shortestDistance = Library.Options.FOV_Radius.Value
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
                local dist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if onScreen and dist < shortestDistance then SilentAimTarget = plr.Character.Head shortestDistance = dist end
            end
        end
    end
    
    for i=1, 128 do AllLines[i].Visible = false end
    if not Library.Toggles.ESP_Enabled.Value then return end
    
    for i, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onScreen then
                local o = (i-1)*5
                if Library.Toggles.ESP_Tracers.Value then
                    AllLines[o+1].Color = Library.Options.Tracer_Color.Value
                    AllLines[o+1].From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    AllLines[o+1].To = Vector2.new(pos.X, pos.Y)
                    AllLines[o+1].Visible = true
                end
                -- Box/Corner logic here...
            end
        end
    end
end)

MainGroup:AddToggle("ESP_Enabled", {Text="Enable ESP"})
MainGroup:AddToggle("ESP_Tracers", {Text="Enable Tracers"})
local OptionsGroup = ESPTab:AddRightGroupbox("Options")
OptionsGroup:AddLabel("Tracer Color"):AddColorPicker("Tracer_Color", {Default = Color3.fromRGB(255, 0, 0)})
OptionsGroup:AddLabel("Box Color"):AddColorPicker("ESP_BoxColor", {Default = Color3.fromRGB(255, 255, 255)})

--------------------------------------------------------------------------------
-- SILENT AIM HOOKS & COMBAT
--------------------------------------------------------------------------------
local oldNamecall; oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if not checkcaller() and Library.Toggles.SilentAim_Enabled.Value and SilentAimTarget and (method == "Raycast" or method == "FindPartOnRay") then
        args[2] = (SilentAimTarget.Position - args[1]).Unit * 1000
        return oldNamecall(self, unpack(args))
    end
    return oldNamecall(self, ...)
end)

local CombatTab = Window:AddTab("Combat", "swords")
local HitboxGroup = CombatTab:AddLeftGroupbox("Hitbox Expander")
HitboxGroup:AddToggle("Hitbox_Enabled", {Text="Enable Hitboxes", Callback = function(v) _G.Disabled = v end})
HitboxGroup:AddSlider("Hitbox_Size", {Text="Hitbox Size", Default=15, Min=2, Max=50, Callback = function(v) _G.HeadSize = v end})

RunService.RenderStepped:Connect(function()
    if _G.Disabled then
        for _, v in next, Players:GetPlayers() do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function() v.Character.HumanoidRootPart.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize) v.Character.HumanoidRootPart.Transparency = 1 v.Character.HumanoidRootPart.CanCollide = false end)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- PLAYERS & CONFIG
--------------------------------------------------------------------------------
local PlayerTab = Window:AddTab("Players", "people")
local PlayerGroup = PlayerTab:AddLeftGroupbox("Server List")
PlayerGroup:AddButton({Text = "Reset Camera", Func = function() Camera.CameraSubject = LocalPlayer.Character.Humanoid end})
for _, plr in pairs(Players:GetPlayers()) do
    PlayerGroup:AddButton({Text = "Spectate " .. plr.Name, Func = function() if plr.Character and plr.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = plr.Character.Humanoid end end})
end

local ConfigTab = Window:AddTab("Config", "file-text")
local function SaveConfig() if writefile then local d={Toggles={},Options={}} for n,v in pairs(Library.Toggles) do d.Toggles[n]=v.Value end for n,v in pairs(Library.Options) do if typeof(v.Value)=="Color3" then d.Options[n]={v.Value.R,v.Value.G,v.Value.B} else d.Options[n]=v.Value end end writefile("mspaint_"..LocalPlayer.Name..".json", HttpService:JSONEncode(d)) end end
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Save Settings", Func=SaveConfig})

local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
if q then q([[if not getgenv().MSPaintLoaded then loadstring(game:HttpGet("https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/sniper.lua"))() end]]) end
LocalPlayer.OnTeleport:Connect(SaveConfig)
