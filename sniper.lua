-- Prevent multiple windows
if getgenv().MSPaintLoaded then return end
getgenv().MSPaintLoaded = true

_G.HeadSize = 15
_G.Disabled = false 

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Initialize Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua", true))()
local Window = Library:CreateWindow({Title = "mspaint", Footer = "Sniper Arena", AutoShow = true, ToggleKeybind = Enum.KeyCode.Zero})

--------------------------------------------------------------------------------
-- TAB: ESP
--------------------------------------------------------------------------------
local ESPTab = Window:AddTab("ESP", "eye")
local MainGroup = ESPTab:AddLeftGroupbox("Visuals")
local OptGroup = ESPTab:AddRightGroupbox("Customization")
local AllLines = {} for i=1, 128 do AllLines[i] = Drawing.new("Line"); AllLines[i].Visible = false end

MainGroup:AddToggle("ESP_Enabled", {Text="Enable ESP"})
MainGroup:AddToggle("ESP_Tracers", {Text="Enable Tracers"})
MainGroup:AddToggle("ESP_CornerBox", {Text="Corner Mode"})
MainGroup:AddToggle("TeamCheck", {Text="Team Check"})
OptGroup:AddLabel("Tracer Color"):AddColorPicker("Tracer_Color", {Default = Color3.fromRGB(255, 0, 0)})
OptGroup:AddLabel("Box Color"):AddColorPicker("Box_Color", {Default = Color3.fromRGB(255, 255, 255)})

--------------------------------------------------------------------------------
-- TAB: COMBAT
--------------------------------------------------------------------------------
local CombatTab = Window:AddTab("Combat", "swords")
local HitGroup = CombatTab:AddLeftGroupbox("Hitboxes")
local LockGroup = CombatTab:AddRightGroupbox("Camera Lock")

HitGroup:AddToggle("Hitbox_Enabled", {Text="Enable Hitboxes", Callback = function(v) _G.Disabled = v end})
HitGroup:AddSlider("Hitbox_Size", {Text="Hitbox Size", Default=15, Min=2, Max=50, Callback = function(v) _G.HeadSize = v end})

LockGroup:AddToggle("CamLock_Enabled", {Text = "Enable Cam Lock"})
LockGroup:AddKeybind("Lock_Key", {Text = "Lock Keybind", Default = Enum.KeyCode.E})
LockGroup:AddSlider("Smoothing", {Text = "Smoothing", Default = 15, Min = 1, Max = 30})
LockGroup:AddSlider("Prediction", {Text = "Prediction", Default = 0, Min = 0, Max = 10})

--------------------------------------------------------------------------------
-- TAB: SOCIALS
--------------------------------------------------------------------------------
local SocialTab = Window:AddTab("Socials", "heart")
local LinkGroup = SocialTab:AddLeftGroupbox("Copy Links")
local LogoGroup = SocialTab:AddRightGroupbox("Logos")

LinkGroup:AddButton({Text = "Copy Discord", Func = function() setclipboard("https://discord.gg/saXzuhsFbj"); Library:Notify("Copied Discord!", 3) end})
LinkGroup:AddButton({Text = "Copy TikTok", Func = function() setclipboard("https://www.tiktok.com/@1l1l11111l1"); Library:Notify("Copied TikTok!", 3) end})

local function AddLogo(url) 
    local i = Instance.new("ImageLabel", LogoGroup.Groupbox)
    i.Size = UDim2.new(0, 100, 0, 100)
    i.Image = url
    i.BackgroundTransparency = 1
end
AddLogo("https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/Screenshot%202026-07-04%20222940-Photoroom.png")
AddLogo("https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/Screenshot%202026-07-04%20222929-Photoroom.png")

--------------------------------------------------------------------------------
-- TAB: CONFIG
--------------------------------------------------------------------------------
local ConfigTab = Window:AddTab("Config", "file-text")
local ManageGroup = ConfigTab:AddLeftGroupbox("Management")
local ConfigFile = "mspaint_" .. LocalPlayer.Name .. ".json"

local function SaveConfig() if writefile then local d={Toggles={},Options={}} for n,v in pairs(Library.Toggles) do d.Toggles[n]=v.Value end for n,v in pairs(Library.Options) do if typeof(v.Value)=="Color3" then d.Options[n]={v.Value.R,v.Value.G,v.Value.B} else d.Options[n]=v.Value end end writefile(ConfigFile, HttpService:JSONEncode(d)) end end
local function LoadConfig() if readfile and isfile(ConfigFile) then local d = HttpService:JSONDecode(readfile(ConfigFile)) if d.Toggles then for n,v in pairs(d.Toggles) do if Library.Toggles[n] then Library.Toggles[n]:SetValue(v) end end end if d.Options then for n,v in pairs(d.Options) do if Library.Options[n] then if type(v)=="table" then Library.Options[n]:SetValueRGB(Color3.new(v[1],v[2],v[3])) else Library.Options[n]:SetValue(v) end end end end end end

ManageGroup:AddButton({Text="Save Settings", Func=SaveConfig})
ManageGroup:AddButton({Text="Load Settings", Func=LoadConfig})

--------------------------------------------------------------------------------
-- MASTER LOGIC LOOP
--------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    -- ESP
    if Library.Toggles.ESP_Enabled.Value then
        for i, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and (not Library.Toggles.TeamCheck.Value or plr.Team ~= LocalPlayer.Team) then
                local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
                if onScreen then
                    local scale = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position + Vector3.new(0, 2.5, 0)).Y - Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position - Vector3.new(0, 2.5, 0)).Y
                    local w, h = scale * 0.6, scale
                    local x, y = pos.X, pos.Y
                    local l, r, t, b = x-w/2, x+w/2, y-h/2, y+h/2
                    local o = (i-1)*8
                    if Library.Toggles.ESP_Tracers.Value then AllLines[o+1].From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); AllLines[o+1].To = Vector2.new(x, y); AllLines[o+1].Color = Library.Options.Tracer_Color.Value; AllLines[o+1].Visible = true end
                    local lines = Library.Toggles.ESP_CornerBox.Value and {{l,t,l+w/4,t},{l,t,l,t+h/4},{r,t,r-w/4,t},{r,t,r,t+h/4},{r,b,r-w/4,b},{r,b,r,b-h/4},{l,b,l+w/4,b},{l,b,l,b-h/4}} or {{l,t,r,t},{r,t,r,b},{r,b,l,b},{l,b,l,t}}
                    for j=1, #lines do AllLines[o+1+j].Color = Library.Options.Box_Color.Value; AllLines[o+1+j].From = Vector2.new(lines[j][1], lines[j][2]); AllLines[o+1+j].To = Vector2.new(lines[j][3], lines[j][4]); AllLines[o+1+j].Visible = true end
                else for j=0, 8 do AllLines[(i-1)*8+j].Visible = false end end
            end
        end
    else for i=1, 128 do AllLines[i].Visible = false end end

    -- Hitboxes
    if _G.Disabled then
        for _, v in next, Players:GetPlayers() do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function() v.Character.HumanoidRootPart.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize); v.Character.HumanoidRootPart.Transparency = 1; v.Character.HumanoidRootPart.CanCollide = false end)
            end
        end
    end

    -- Cam Lock
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
            local pred = closest.Velocity * (Library.Options.Prediction.Value / 10)
            local targetCFrame = CFrame.new(Camera.CFrame.Position, closest.Position + pred)
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / Library.Options.Smoothing.Value)
        end
    end
end)

task.delay(1, LoadConfig)
