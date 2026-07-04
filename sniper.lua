-- Prevent multiple windows
if getgenv().MSPaintLoaded then return end
getgenv().MSPaintLoaded = true

_G.HeadSize = 15
_G.Disabled = false 

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua", true))()
local Window = Library:CreateWindow({Title = "mspaint", Footer = "Sniper Arena", AutoShow = true, ToggleKeybind = Enum.KeyCode.Zero})

--------------------------------------------------------------------------------
-- HUD & SERVER STATUS (Visuals/Info)
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
StatusText.Text = "Loading Status..."

RunService.RenderStepped:Connect(function()
    local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    local fps = math.floor(workspace:GetRealPhysicsFPS())
    StatusText.Text = string.format("FPS: %d\nPing: %dms\nPlayers: %d", fps, ping, #Players:GetPlayers())
end)

--------------------------------------------------------------------------------
-- PLAYERS TAB (Spectate System)
--------------------------------------------------------------------------------
local PlayerTab = Window:AddTab("Players", "people")
local PlayerGroup = PlayerTab:AddLeftGroupbox("Server List")

local function Spectate(plr)
    if plr and plr.Character and plr.Character:FindFirstChild("Humanoid") then
        Camera.CameraSubject = plr.Character.Humanoid
    end
end

local function RefreshList()
    PlayerGroup:AddDivider()
    for _, plr in pairs(Players:GetPlayers()) do
        PlayerGroup:AddButton({Text = "Spectate " .. plr.Name, Func = function() Spectate(plr) end})
    end
    PlayerGroup:AddButton({Text = "Reset Camera", Func = function() Camera.CameraSubject = LocalPlayer.Character.Humanoid end})
end
RefreshList()

--------------------------------------------------------------------------------
-- ESP TAB
--------------------------------------------------------------------------------
local ESPTab = Window:AddTab("ESP", "eye")
local MainGroup = ESPTab:AddLeftGroupbox("Visuals")
local AllLines = {} for i=1, 32 do AllLines[i] = Drawing.new("Line"); AllLines[i].Visible = false end

RunService.RenderStepped:Connect(function()
    if not Library.Toggles.ESP_Enabled.Value then for i=1, 32 do AllLines[i].Visible = false end return end
    for i, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onScreen then
                AllLines[i].From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                AllLines[i].To = Vector2.new(pos.X, pos.Y)
                AllLines[i].Color = Library.Options.ESP_BoxColor.Value
                AllLines[i].Visible = true
            else AllLines[i].Visible = false end
        else AllLines[i].Visible = false end
    end
end)

MainGroup:AddToggle("ESP_Enabled", {Text="Enable Tracers"})
ESPTab:AddRightGroupbox("Options"):AddLabel("Tracer Color"):AddColorPicker("ESP_BoxColor", {Default=Color3.new(1,1,1)})

--------------------------------------------------------------------------------
-- COMBAT TAB
--------------------------------------------------------------------------------
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
-- CONFIG & TELEPORT
--------------------------------------------------------------------------------
local ConfigFile = "mspaint_" .. LocalPlayer.Name .. ".json"
local function SaveConfig() if writefile then local d={Toggles={},Options={}} for n,v in pairs(Library.Toggles) do d.Toggles[n]=v.Value end for n,v in pairs(Library.Options) do if typeof(v.Value)=="Color3" then d.Options[n]={v.Value.R,v.Value.G,v.Value.B} else d.Options[n]=v.Value end end writefile(ConfigFile, HttpService:JSONEncode(d)) end end
local function LoadConfig() if readfile and isfile(ConfigFile) then local d = HttpService:JSONDecode(readfile(ConfigFile)) if d.Toggles then for n,v in pairs(d.Toggles) do if Library.Toggles[n] then Library.Toggles[n]:SetValue(v) end end end if d.Options then for n,v in pairs(d.Options) do if Library.Options[n] then if type(v)=="table" then Library.Options[n]:SetValueRGB(Color3.new(v[1],v[2],v[3])) else Library.Options[n]:SetValue(v) end end end end end end

local ConfigTab = Window:AddTab("Config", "file-text")
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Save Settings", Func=SaveConfig})
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Load Settings", Func=LoadConfig})

local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
if q then q([[if not getgenv().MSPaintLoaded then loadstring(game:HttpGet("https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/sniper.lua"))() end]]) end
LocalPlayer.OnTeleport:Connect(SaveConfig)
task.delay(1, LoadConfig)
