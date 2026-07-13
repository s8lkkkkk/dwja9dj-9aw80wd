-- Cleanup existing instances
local CoreGui = game:GetService("CoreGui")
if CoreGui:FindFirstChild("MSPaint_UI") then CoreGui:FindFirstChild("MSPaint_UI"):Destroy() end
if CoreGui:FindFirstChild("MSPaint_Circle") then CoreGui:FindFirstChild("MSPaint_Circle"):Destroy() end

getgenv().MSPaintLoaded = true
_G.HeadSize = 15
_G.Disabled = false 

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua", true))()
local Window = Library:CreateWindow({Title = "mspaint", Footer = "Sniper Arena", AutoShow = true, ToggleKeybind = nil})

--------------------------------------------------------------------------------
-- ORIGINAL MSPAINT UI & CIRCLE LOGIC
--------------------------------------------------------------------------------
local CircleGui = Instance.new("ScreenGui", CoreGui)
CircleGui.Name = "MSPaint_Circle"
local CircleButton = Instance.new("TextButton", CircleGui)
CircleButton.Size = UDim2.new(0, 50, 0, 50)
CircleButton.Position = UDim2.new(0, 20, 0.5, 0)
CircleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
CircleButton.Text = "O"
CircleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CircleButton.Visible = false
CircleButton.ZIndex = 999
local UICorner = Instance.new("UICorner", CircleButton)
UICorner.CornerRadius = UDim.new(1, 0)
CircleButton.MouseButton1Click:Connect(function() Window:Toggle() end)
local function UpdateUIState() CircleButton.Visible = not Window.Visible end
local OldToggle = Window.Toggle
Window.Toggle = function(self, ...) OldToggle(self, ...) UpdateUIState() end

--------------------------------------------------------------------------------
-- ORIGINAL TABS
--------------------------------------------------------------------------------
local ConfigTab = Window:AddTab("Config", "file-text")
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Save Settings", Func=function() end})
ConfigTab:AddLeftGroupbox("Management"):AddButton({Text="Load Settings", Func=function() end})
ConfigTab:AddRightGroupbox("UI"):AddButton({Text="Minimize", Func=function() Window:Toggle() end})

local PlayerTab = Window:AddTab("Players", "people")
PlayerTab:AddLeftGroupbox("Server"):AddButton({Text = "Reset Camera", Func = function() Camera.CameraSubject = LocalPlayer.Character.Humanoid end})

local ESPTab = Window:AddTab("ESP", "eye")
local MainGroup = ESPTab:AddLeftGroupbox("Visuals")
MainGroup:AddToggle("ESP_Enabled", {Text="Enable Box ESP"})
MainGroup:AddToggle("ESP_CornerBox", {Text="Corner Mode"})
MainGroup:AddToggle("ESP_Tracers", {Text="Enable Tracers"})
ESPTab:AddRightGroupbox("Options"):AddLabel("Box Color"):AddColorPicker("ESP_BoxColor", {Default=Color3.new(1,1,1)})

local CombatTab = Window:AddTab("Combat", "swords")
local HitboxGroup = CombatTab:AddLeftGroupbox("Hitbox Expander")
HitboxGroup:AddToggle("Hitbox_Enabled", {Text="Enable Hitboxes", Callback = function(v) _G.Disabled = v end})
HitboxGroup:AddSlider("Hitbox_Size", {Text="Hitbox Size", Default=15, Min=2, Max=50, Callback = function(v) _G.HeadSize = v end})

--------------------------------------------------------------------------------
-- YOUR ORIGINAL DUPE LOGIC (Merged)
--------------------------------------------------------------------------------
local DuperTab = Window:AddTab("Duper", "layers")
local DupeBox = DuperTab:AddLeftGroupbox("Duper Tools")
DupeBox:AddInput("CustomItem", {Text="Enter name exactly..."})
DupeBox:AddSlider("Amount", {Text="Copies", Default=1, Min=1, Max=50})
DupeBox:AddButton({Text=">>> EXECUTE DUPE <<<", Func=function()
    local targetName = Library.Options.CustomItem.Value
    local dupeAmount = Library.Options.Amount.Value
    local count = 0
    local found = false
    local function cleanString(s) return string.lower(string.gsub(s, "%s+", " ")) end
    local cleanTarget = cleanString(targetName)
    local function findAndClone(parent)
        for _, item in ipairs(parent:GetChildren()) do
            if item.Name == "Template" then
                for _, desc in ipairs(item:GetDescendants()) do
                    if desc:IsA("TextLabel") and cleanString(desc.Text) == cleanTarget then
                        for i = 1, dupeAmount do
                            local clone = item:Clone()
                            for _, d in pairs(clone:GetDescendants()) do if d:IsA("LuaSourceContainer") then d:Destroy() end end
                            clone.Parent = parent
                            clone.Visible = true
                            count = count + 1
                        end
                        found = true
                        break 
                    end
                end
            end
            if not found then findAndClone(item) end
        end
    end
    findAndClone(PlayerGui)
end})

--------------------------------------------------------------------------------
-- NEW FEATURES TAB
--------------------------------------------------------------------------------
local MiscTab = Window:AddTab("Misc", "zap")
local F1 = MiscTab:AddLeftGroupbox("Player")
F1:AddToggle("WalkSpeed", {Text="Inf Speed"})
F1:AddToggle("JumpPower", {Text="Inf Jump"})
F1:AddButton({Text="Rejoin", Func=function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end})
local F2 = MiscTab:AddRightGroupbox("Perf")
F2:AddButton({Text="Clean Workspace", Func=function() for _,v in pairs(workspace:GetDescendants()) do if v:IsA("ParticleEmitter") then v:Destroy() end end end})
F2:AddButton({Text="Optimize Mem", Func=function() collectgarbage() end})
local F3 = MiscTab:AddLeftGroupbox("Extra")
F3:AddToggle("FullBright", {Text="Full Bright"})
F3:AddToggle("NoFall", {Text="No Fall Damage"})
F3:AddToggle("AutoClick", {Text="Auto Clicker"})
F3:AddToggle("Fly", {Text="Fly Mode"})
F3:AddToggle("FastHeal", {Text="Fast Heal"})

--------------------------------------------------------------------------------
-- ORIGINAL RENDER LOOP & AUTO-EXEC
--------------------------------------------------------------------------------
local AllLines = {} for i=1, 128 do AllLines[i] = Drawing.new("Line"); AllLines[i].Visible = false end
RunService.RenderStepped:Connect(function()
    if Library.Toggles.ESP_Enabled and Library.Toggles.ESP_Enabled.Value then
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
                    local lines = Library.Toggles.ESP_CornerBox.Value and {{l,t,l+w/4,t},{l,t,l,t+h/4},{r,t,r-w/4,t},{r,t,r,t+h/4},{r,b,r-w/4,b},{r,b,r,b-h/4},{l,b,l+w/4,b},{l,b,l,t+h/4}} or {{l,t,r,t},{r,t,r,b},{r,b,l,b},{l,b,l,t}}
                    for j=1, #lines do AllLines[o+1+j].Color = Library.Options.ESP_BoxColor.Value; AllLines[o+1+j].From = Vector2.new(lines[j][1], lines[j][2]); AllLines[o+1+j].To = Vector2.new(lines[j][3], lines[j][4]); AllLines[o+1+j].Visible = true end
                else for j=0, 8 do AllLines[(i-1)*8+j].Visible = false end end
            end
        end
    else for i=1, 128 do AllLines[i].Visible = false end end

    if _G.Disabled then
        for _, v in next, Players:GetPlayers() do
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function() v.Character.HumanoidRootPart.Size = Vector3.new(_G.HeadSize, _G.HeadSize, _G.HeadSize); v.Character.HumanoidRootPart.Transparency = 1; v.Character.HumanoidRootPart.CanCollide = false end)
            end
        end
    end
end)

local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
if q then q([[repeat task.wait() until game:IsLoaded(); loadstring(game:HttpGet("https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/sniper.lua"))()]]) end
