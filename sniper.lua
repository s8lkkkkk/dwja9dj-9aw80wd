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
-- HUD & STATUS
--------------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local StatusFrame = Instance.new("Frame", ScreenGui)
StatusFrame.Size = UDim2.new(0, 180, 0, 100)
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
    local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    local fps = math.floor(workspace:GetRealPhysicsFPS())
    StatusText.Text = string.format("FPS: %d\nPing: %dms\nPlayers: %d", fps, ping, #Players:GetPlayers())
end)

--------------------------------------------------------------------------------
-- ESP TAB
--------------------------------------------------------------------------------
local ESPTab = Window:AddTab("ESP", "eye")
local MainGroup = ESPTab:AddLeftGroupbox("Visuals")
local AllLines = {} for i=1, 128 do AllLines[i] = Drawing.new("Line"); AllLines[i].Visible = false end

RunService.RenderStepped:Connect(function()
    if not Library.Toggles.ESP_Enabled.Value then for i=1, 128 do AllLines[i].Visible = false end return end
    for i, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onScreen then
                local scale = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position + Vector3.new(0, 2.5, 0)).Y - Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position - Vector3.new(0, 2.5, 0)).Y
                local w, h = scale * 0.6, scale
                local x, y = pos.X, pos.Y
                local l, r, t, b = x-w/2, x+w/2, y-h/2, y+h/2
                local o = (i-1)*8
                if Library.Toggles.ESP_Tracers.Value then AllLines[o+1].From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); AllLines[o+1].To = Vector2.new(x, y); AllLines[o+1].Color = Library.Options.ESP_BoxColor.Value; AllLines[o+1].Visible = true end
                local lines = Library.Toggles.ESP_CornerBox.Value and {{l,t,l+w/4,t},{l,t,l,t+h/4},{r,t,r-w/4,t},{r,t,r,t+h/4},{r,b,r-w/4,b},{r,b,r,b-h/4},{l,b,l+w/4,b},{l,b,l,b-h/4}} or {{l,t,r,t},{r,t,r,b},{r,b,l,b},{l,b,l,t}}
                for j=1, #lines do AllLines[o+1+j].Color = Library.Options.ESP_BoxColor.Value; AllLines[o+1+j].From = Vector2.new(lines[j][1], lines[j][2]); AllLines[o+1+j].To = Vector2.new(lines[j][3], lines[j][4]); AllLines[o+1+j].Visible = true end
            else for j=0, 8 do AllLines[(i-1)*8+j].Visible = false end end
        end
    end
end)

MainGroup:AddToggle("ESP_Enabled", {Text="Enable Box ESP"})
MainGroup:AddToggle("ESP_CornerBox", {Text="Corner Mode"})
MainGroup:AddToggle("ESP_Tracers", {Text="Enable Tracers"})
ESPTab:AddRightGroupbox("Options"):AddLabel("Box Color"):AddColorPicker("ESP_BoxColor", {Default=Color3.new(1,1,1)})

--------------------------------------------------------------------------------
-- COMBAT TAB
--------------------------------------------------------------------------------
local CombatTab = Window:AddTab("Combat", "swords")
local HitboxGroup = CombatTab:AddLeftGroupbox("Hitbox Expander")
local LockGroup = CombatTab:AddRightGroupbox("Camera Lock")

HitboxGroup:AddToggle("Hitbox_Enabled", {Text="Enable Hitboxes", Callback = function(v) _G.Disabled = v end})
HitboxGroup:AddSlider("Hitbox_Size", {Text="Hitbox Size", Default=15, Min=2, Max=50, Callback = function(v) _G.HeadSize = v end})

LockGroup:AddToggle("CamLock_Enabled", {Text = "Enable Cam Lock"})
LockGroup:AddKeybind("Lock_Key", {Text = "Lock Key", Default = Enum.KeyCode.E})
LockGroup:AddSlider("Smoothing", {Text = "Smoothing", Default = 15, Min = 1, Max = 30})

RunService.RenderStepped:Connect(function()
    -- Hitbox Logic
    if _G.Disabled then
        for _, v in next, Players:GetPlayers() do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function() v.Character.HumanoidRootPart.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize); v.Character.HumanoidRootPart.Transparency = 1; v.Character.HumanoidRootPart.CanCollide = false end)
            end
        end
    end
    -- Cam Lock Logic
    if Library.Toggles.CamLock_Enabled.Value and UserInputService:IsKeyDown(Library.Options.Lock_Key.Value) then
        local closest, dist = nil, 500
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                local mDist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if onScreen and mDist < dist then closest = plr.Character.HumanoidRootPart; dist = mDist end
            end
        end
        if closest then
            local targetCFrame = CFrame.new(Camera.CFrame.Position, closest.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / Library.Options.Smoothing.Value)
        end
    end
end)

--------------------------------------------------------------------------------
-- SOCIALS & CONFIG
--------------------------------------------------------------------------------
local SocialTab = Window:AddTab("Socials", "heart")
local SocialGroup = SocialTab:AddLeftGroupbox("Copy Links")
local IconGroup = SocialTab:AddRightGroupbox("Logos")
SocialGroup:AddButton({Text = "Copy Discord", Func = function() setclipboard("https://discord.gg/saXzuhsFbj"); Library:Notify("Copied Discord!", 3) end})
SocialGroup:AddButton({Text = "Copy TikTok", Func = function() setclipboard("https://www.tiktok.com/@1l1l11111l1"); Library:Notify("Copied TikTok!", 3) end})
Instance.new("ImageLabel", IconGroup.Groupbox).Image = "https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/Screenshot%202026-07-04%20222940-Photoroom.png"
Instance.new("ImageLabel", IconGroup.Groupbox).Image = "https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/Screenshot%202026-07-04%20222929-Photoroom.png"

local ConfigTab = Window:AddTab("Config", "file-text")
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Save Settings", Func=function() end})
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Load Settings", Func=function() end})

task.delay(1, function() end)
