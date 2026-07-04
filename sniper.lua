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
        local shortestDist = Library.Options.FOV_Radius.Value
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
                local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
                local dist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if onScreen and dist < shortestDist then SilentAimTarget = plr.Character.Head shortestDist = dist end
            end
        end
    end
    
    for i=1, 128 do AllLines[i].Visible = false end
    if not Library.Toggles.ESP_Enabled.Value then return end
    
    for i, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onScreen then
                local scale = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position + Vector3.new(0, 2.5, 0)).Y - Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position - Vector3.new(0, 2.5, 0)).Y
                local w, h = scale * 0.6, scale
                local x, y = pos.X, pos.Y
                local l, r, t, b = x-w/2, x+w/2, y-h/2, y+h/2
                local o = (i-1)*12
                
                if Library.Toggles.ESP_Tracers.Value then
                    AllLines[o+1].Color = Library.Options.Tracer_Color.Value
                    AllLines[o+1].From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    AllLines[o+1].To = Vector2.new(x, y+h/2)
                    AllLines[o+1].Visible = true
                end
                
                if Library.Toggles.ESP_CornerBox.Value then
                    local lines = {{l,t,l+w/4,t}, {l,t,l,t+h/4}, {r,t,r-w/4,t}, {r,t,r,t+h/4}, {r,b,r-w/4,b}, {r,b,r,b-h/4}, {l,b,l+w/4,b}, {l,b,l,b-h/4}}
                    for j=1, 8 do AllLines[o+1+j].Color = Library.Options.ESP_BoxColor.Value; AllLines[o+1+j].From = Vector2.new(lines[j][1], lines[j][2]); AllLines[o+1+j].To = Vector2.new(lines[j][3], lines[j][4]); AllLines[o+1+j].Visible = true end
                else
                    local lines = {{l,t,r,t}, {r,t,r,b}, {r,b,l,b}, {l,b,l,t}}
                    for j=1, 4 do AllLines[o+1+j].Color = Library.Options.ESP_BoxColor.Value; AllLines[o+1+j].From = Vector2.new(lines[j][1], lines[j][2]); AllLines[o+1+j].To = Vector2.new(lines[j][3], lines[j][4]); AllLines[o+1+j].Visible = true end
                end
            end
        end
    end
end)

MainGroup:AddToggle("ESP_Enabled", {Text="Enable Box ESP"})
MainGroup:AddToggle("ESP_CornerBox", {Text="Corner Mode"})
MainGroup:AddToggle("ESP_Tracers", {Text="Enable Tracers"})
local OptionsGroup = ESPTab:AddRightGroupbox("Visual Options")
OptionsGroup:AddLabel("Tracer Color"):AddColorPicker("Tracer_Color", {Default = Color3.fromRGB(255, 0, 0)})
OptionsGroup:AddLabel("Box Color"):AddColorPicker("ESP_BoxColor", {Default = Color3.fromRGB(255, 255, 255)})

--------------------------------------------------------------------------------
-- COMBAT TAB
--------------------------------------------------------------------------------
local CombatTab = Window:AddTab("Combat", "swords")
local HitboxGroup = CombatTab:AddLeftGroupbox("Hitbox Expander")
HitboxGroup:AddToggle("Hitbox_Enabled", {Text="Enable Hitboxes", Callback = function(v) _G.Disabled = v end})
HitboxGroup:AddSlider("Hitbox_Size", {Text="Hitbox Size", Default=15, Min=2, Max=50, Callback = function(v) _G.HeadSize = v end})

local oldNamecall; oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if not checkcaller() and Library.Toggles.SilentAim_Enabled.Value and SilentAimTarget and (method == "Raycast" or method == "FindPartOnRay") then
        args[2] = (SilentAimTarget.Position - args[1]).Unit * 1000
        return oldNamecall(self, unpack(args))
    end
    return oldNamecall(self, ...)
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
local function LoadConfig() if readfile and isfile("mspaint_"..LocalPlayer.Name..".json") then local d=HttpService:JSONDecode(readfile("mspaint_"..LocalPlayer.Name..".json")) if d.Toggles then for n,v in pairs(d.Toggles) do if Library.Toggles[n] then Library.Toggles[n]:SetValue(v) end end end if d.Options then for n,v in pairs(d.Options) do if Library.Options[n] then if type(v)=="table" then Library.Options[n]:SetValueRGB(Color3.new(v[1],v[2],v[3])) else Library.Options[n]:SetValue(v) end end end end end end
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Save Settings", Func=SaveConfig})
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Load Settings", Func=LoadConfig})

local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
if q then q([[if not getgenv().MSPaintLoaded then loadstring(game:HttpGet("https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/sniper.lua"))() end]]) end
LocalPlayer.OnTeleport:Connect(SaveConfig)
task.delay(1, LoadConfig)
