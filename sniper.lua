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

local function onCharAdded(plr)
    giveSlot(plr)
    takeSlot(plr)
end

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

    local T = Library.Toggles
    local O = Library.Options
    local teamCheck = T.ESP_TeamCheck and T.ESP_TeamCheck.Value
    local maxDist = O.ESP_MaxDistance and O.ESP_MaxDistance.Value
    local boxColor = O.ESP_BoxColor and O.ESP_BoxColor.Value or Color3.fromRGB(255, 255, 255)
    local thickness = O.ESP_Thickness and O.ESP_Thickness.Value or 1
    local cornerBox = T.ESP_CornerBox and T.ESP_CornerBox.Value

    for i = 1, #AllLines do AllLines[i].Visible = false end

    for plr, slot in pairs(LineSlots) do
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        local skip = not char or not root or not hum or hum.Health <= 0

        if not skip and teamCheck and plr.Team == LocalPlayer.Team then
            skip = true
        end

        local pos
        local screenPos
        local viewportPos

        if not skip then
            pos = root.Position
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local dist = myRoot and (pos - myRoot.Position).Magnitude or 0
            if maxDist and maxDist > 0 and dist > maxDist then skip = true end
        end

        if not skip then
            viewportPos = Camera:WorldToViewportPoint(pos)
            if viewportPos.Z <= 0 then skip = true end
        end

        if skip then
            local o = (slot - 1) * LINES_PER_PLAYER
            for j = 1, LINES_PER_PLAYER do AllLines[o + j].Visible = false end
        else
            screenPos = viewportPos
            local scale = Camera:WorldToViewportPoint(pos + Vector3.new(0, 2.5, 0)).Y - Camera:WorldToViewportPoint(pos - Vector3.new(0, 2.5, 0)).Y
            local width = scale * 0.6
            local height = scale
            local x, y = screenPos.X, screenPos.Y
            local left = x - width / 2
            local right = x + width / 2
            local top = y - height / 2
            local bottom = y + height / 2
            local o = (slot - 1) * LINES_PER_PLAYER

            if cornerBox then
                local cw = width * 0.25
                local ch = height * 0.25

                AllLines[o + 1].Color = Color3.new(0, 0, 0); AllLines[o + 1].Transparency = 1; AllLines[o + 1].Thickness = thickness + 2; AllLines[o + 1].From = Vector2.new(left, top); AllLines[o + 1].To = Vector2.new(left + cw, top); AllLines[o + 1].Visible = true
                AllLines[o + 2].Color = Color3.new(0, 0, 0); AllLines[o + 2].Transparency = 1; AllLines[o + 2].Thickness = thickness + 2; AllLines[o + 2].From = Vector2.new(left, top); AllLines[o + 2].To = Vector2.new(left, top + ch); AllLines[o + 2].Visible = true
                AllLines[o + 3].Color = Color3.new(0, 0, 0); AllLines[o + 3].Transparency = 1; AllLines[o + 3].Thickness = thickness + 2; AllLines[o + 3].From = Vector2.new(right, top); AllLines[o + 3].To = Vector2.new(right - cw, top); AllLines[o + 3].Visible = true
                AllLines[o + 4].Color = Color3.new(0, 0, 0); AllLines[o + 4].Transparency = 1; AllLines[o + 4].Thickness = thickness + 2; AllLines[o + 4].From = Vector2.new(right, top); AllLines[o + 4].To = Vector2.new(right, top + ch); AllLines[o + 4].Visible = true
                AllLines[o + 5].Color = Color3.new(0, 0, 0); AllLines[o + 5].Transparency = 1; AllLines[o + 5].Thickness = thickness + 2; AllLines[o + 5].From = Vector2.new(right, bottom); AllLines[o + 5].To = Vector2.new(right - cw, bottom); AllLines[o + 5].Visible = true
                AllLines[o + 6].Color = Color3.new(0, 0, 0); AllLines[o + 6].Transparency = 1; AllLines[o + 6].Thickness = thickness + 2; AllLines[o + 6].From = Vector2.new(right, bottom); AllLines[o + 6].To = Vector2.new(right, bottom - ch); AllLines[o + 6].Visible = true
                AllLines[o + 7].Color = Color3.new(0, 0, 0); AllLines[o + 7].Transparency = 1; AllLines[o + 7].Thickness = thickness + 2; AllLines[o + 7].From = Vector2.new(left, bottom); AllLines[o + 7].To = Vector2.new(left + cw, bottom); AllLines[o + 7].Visible = true
                AllLines[o + 8].Color = Color3.new(0, 0, 0); AllLines[o + 8].Transparency = 1; AllLines[o + 8].Thickness = thickness + 2; AllLines[o + 8].From = Vector2.new(left, bottom); AllLines[o + 8].To = Vector2.new(left, bottom - ch); AllLines[o + 8].Visible = true

                AllLines[o + 9].Color = boxColor; AllLines[o + 9].Transparency = 1; AllLines[o + 9].Thickness = thickness; AllLines[o + 9].From = Vector2.new(left, top); AllLines[o + 9].To = Vector2.new(left + cw, top); AllLines[o + 9].Visible = true
                AllLines[o + 10].Color = boxColor; AllLines[o + 10].Transparency = 1; AllLines[o + 10].Thickness = thickness; AllLines[o + 10].From = Vector2.new(left, top); AllLines[o + 10].To = Vector2.new(left, top + ch); AllLines[o + 10].Visible = true
                AllLines[o + 11].Color = boxColor; AllLines[o + 11].Transparency = 1; AllLines[o + 11].Thickness = thickness; AllLines[o + 11].From = Vector2.new(right, top); AllLines[o + 11].To = Vector2.new(right - cw, top); AllLines[o + 11].Visible = true
                AllLines[o + 12].Color = boxColor; AllLines[o + 12].Transparency = 1; AllLines[o + 12].Thickness = thickness; AllLines[o + 12].From = Vector2.new(right, top); AllLines[o + 12].To = Vector2.new(right, top + ch); AllLines[o + 12].Visible = true
                AllLines[o + 13].Color = boxColor; AllLines[o + 13].Transparency = 1; AllLines[o + 13].Thickness = thickness; AllLines[o + 13].From = Vector2.new(right, bottom); AllLines[o + 13].To = Vector2.new(right - cw, bottom); AllLines[o + 13].Visible = true
                AllLines[o + 14].Color = boxColor; AllLines[o + 14].Transparency = 1; AllLines[o + 14].Thickness = thickness; AllLines[o + 14].From = Vector2.new(right, bottom); AllLines[o + 14].To = Vector2.new(right, bottom - ch); AllLines[o + 14].Visible = true
                AllLines[o + 15].Color = boxColor; AllLines[o + 15].Transparency = 1; AllLines[o + 15].Thickness = thickness; AllLines[o + 15].From = Vector2.new(left, bottom); AllLines[o + 15].To = Vector2.new(left + cw, bottom); AllLines[o + 15].Visible = true
                AllLines[o + 16].Color = boxColor; AllLines[o + 16].Transparency = 1; AllLines[o + 16].Thickness = thickness; AllLines[o + 16].From = Vector2.new(left, bottom); AllLines[o + 16].To = Vector2.new(left, bottom - ch); AllLines[o + 16].Visible = true
            else
                AllLines[o + 1].Color = Color3.new(0, 0, 0); AllLines[o + 1].Transparency = 1; AllLines[o + 1].Thickness = thickness + 2; AllLines[o + 1].From = Vector2.new(left, top); AllLines[o + 1].To = Vector2.new(right, top); AllLines[o + 1].Visible = true
                AllLines[o + 2].Color = Color3.new(0, 0, 0); AllLines[o + 2].Transparency = 1; AllLines[o + 2].Thickness = thickness + 2; AllLines[o + 2].From = Vector2.new(right, top); AllLines[o + 2].To = Vector2.new(right, bottom); AllLines[o + 2].Visible = true
                AllLines[o + 3].Color = Color3.new(0, 0, 0); AllLines[o + 3].Transparency = 1; AllLines[o + 3].Thickness = thickness + 2; AllLines[o + 3].From = Vector2.new(right, bottom); AllLines[o + 3].To = Vector2.new(left, bottom); AllLines[o + 3].Visible = true
                AllLines[o + 4].Color = Color3.new(0, 0, 0); AllLines[o + 4].Transparency = 1; AllLines[o + 4].Thickness = thickness + 2; AllLines[o + 4].From = Vector2.new(left, bottom); AllLines[o + 4].To = Vector2.new(left, top); AllLines[o + 4].Visible = true

                AllLines[o + 5].Color = boxColor; AllLines[o + 5].Transparency = 1; AllLines[o + 5].Thickness = thickness; AllLines[o + 5].From = Vector2.new(left, top); AllLines[o + 5].To = Vector2.new(right, top); AllLines[o + 5].Visible = true
                AllLines[o + 6].Color = boxColor; AllLines[o + 6].Transparency = 1; AllLines[o + 6].Thickness = thickness; AllLines[o + 6].From = Vector2.new(right, top); AllLines[o + 6].To = Vector2.new(right, bottom); AllLines[o + 6].Visible = true
                AllLines[o + 7].Color = boxColor; AllLines[o + 7].Transparency = 1; AllLines[o + 7].Thickness = thickness; AllLines[o + 7].From = Vector2.new(right, bottom); AllLines[o + 7].To = Vector2.new(left, bottom); AllLines[o + 7].Visible = true
                AllLines[o + 8].Color = boxColor; AllLines[o + 8].Transparency = 1; AllLines[o + 8].Thickness = thickness; AllLines[o + 8].From = Vector2.new(left, bottom); AllLines[o + 8].To = Vector2.new(left, top); AllLines[o + 8].Visible = true
            end

            local tracers = T.ESP_Tracers and T.ESP_Tracers.Value
            if tracers then
                local tracerColor = O.ESP_TracerColor and O.ESP_TracerColor.Value or boxColor
                local bottomPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                AllLines[o + 17].Color = tracerColor
                AllLines[o + 17].Transparency = 1 
                AllLines[o + 17].Thickness = thickness
                AllLines[o + 17].From = bottomPos
                AllLines[o + 17].To = Vector2.new(x, y + height / 2)
                AllLines[o + 17].Visible = true
            end
        end
    end
end)

MainGroup:AddToggle("ESP_Enabled", {
    Text = "Bounding Box ESP", Default = false,
    Callback = function(value)
        espEnabled = value
        if not value then
            for i = 1, #AllLines do AllLines[i].Visible = false end
        end
    end,
})

MainGroup:AddToggle("ESP_CornerBox", { Text = "Corner Box", Default = false, Visible = false })
MainGroup:AddToggle("ESP_Tracers", { Text = "Tracers", Default = false, Visible = false })
Library.Toggles.ESP_Enabled:OnChanged(function(value)
    Library.Toggles.ESP_CornerBox:SetVisible(value)
    Library.Toggles.ESP_Tracers:SetVisible(value)
end)

local ESPOptions = ESPTab:AddRightGroupbox("Options")
ESPOptions:AddToggle("ESP_TeamCheck", { Text = "Team Check", Default = false }) 
ESPOptions:AddSlider("ESP_MaxDistance", { Text = "Max Distance", Default = 1000, Min = 0, Max = 5000, Rounding = 0, Suffix = " studs", Compact = false })
ESPOptions:AddSlider("ESP_Thickness", { Text = "Outline Thickness", Default = 1, Min = 1, Max = 6, Rounding = 0, Compact = false })
ESPOptions:AddLabel("Box Color"):AddColorPicker("ESP_BoxColor", { Default = Color3.fromRGB(255, 255, 255) })
ESPOptions:AddLabel("Tracer Color"):AddColorPicker("ESP_TracerColor", { Default = Color3.fromRGB(255, 0, 0) })

--------------------------------------------------------------------------------
-- COMBAT TAB
--------------------------------------------------------------------------------
local CombatTab = Window:AddTab("Combat", "swords")
local AimbotGroup = CombatTab:AddLeftGroupbox("Aimbot")
local HitboxGroup = CombatTab:AddLeftGroupbox("Hitbox Expander") 
local FOVGroup = CombatTab:AddRightGroupbox("Field of View")

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Thickness = 1
FOVCircle.Transparency = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

local aimbotEnabled = false
local aimbotSmoothing = 1
local aimbotTargetPart = "Head"
local teamCheckAimbot = false

local fovRadius = 250 
local fovVisible = false

FOVGroup:AddToggle("Draw_FOV", {
    Text = "Show FOV Circle", Default = false,
    Callback = function(value)
        fovVisible = value
        FOVCircle.Visible = value
    end,
})

FOVGroup:AddSlider("FOV_Radius", {
    Text = "FOV Radius", Default = 250, Min = 10, Max = 800, Rounding = 0,
    Callback = function(value)
        fovRadius = value
        FOVCircle.Radius = value
    end,
})

FOVGroup:AddLabel("FOV Color"):AddColorPicker("FOV_Color", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color) FOVCircle.Color = color end
})

AimbotGroup:AddToggle("Aimbot_Enabled", {
    Text = "Enable Aimbot", Default = false,
    Callback = function(value) aimbotEnabled = value end,
})

AimbotGroup:AddToggle("Aimbot_TeamCheck", {
    Text = "Team Check", Default = false, 
    Callback = function(value) teamCheckAimbot = value end,
})

AimbotGroup:AddSlider("Aimbot_Smoothing", {
    Text = "Smoothing", Default = 1, Min = 1, Max = 10, Rounding = 1,
    Callback = function(value) aimbotSmoothing = value end,
})

AimbotGroup:AddDropdown("Aimbot_Target", {
    Text = "Target Part", Default = "Head", Values = {"Head", "HumanoidRootPart", "Torso"},
    Callback = function(value) aimbotTargetPart = value end,
})

local function getClosestPlayer()
    local closestDist = fovRadius
    local target = nil
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, plr in pairs(Players:GetPlayers()) do
        local char = plr.Character
        local hum = char and char:FindFirstChildWhichIsA("Humanoid")
        
        if plr ~= LocalPlayer and char and hum and hum.Health > 0 then
            if teamCheckAimbot and plr.Team == LocalPlayer.Team then continue end
            
            local actualTarget = aimbotTargetPart
            if actualTarget == "Torso" and char:FindFirstChild("UpperTorso") then
                actualTarget = "UpperTorso"
            end
            
            local part = char:FindFirstChild(actualTarget) or char:FindFirstChild("Head") or char.PrimaryPart
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    
                    if dist < closestDist then
                        closestDist = dist
                        target = part
                    end
                end
            end
        end
    end
    return target
end

local aimbotConn = RunService.RenderStepped:Connect(function()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    if fovVisible then
        FOVCircle.Position = screenCenter
    end

    local isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    if aimbotEnabled and isAiming then
        local targetPart = getClosestPlayer()
        if targetPart then
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                local targetVec2 = Vector2.new(screenPos.X, screenPos.Y)
                local delta = (targetVec2 - screenCenter)
                
                if aimbotSmoothing > 1 then
                    delta = delta / aimbotSmoothing
                end
                
                if mousemoverel then
                    mousemoverel(delta.X, delta.Y)
                else
                    local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
                    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / aimbotSmoothing)
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- HITBOX EXPANDER
--------------------------------------------------------------------------------
local hitboxEnabled = false
local hitboxSize = 15

local function resetHitboxes()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            pcall(function()
                local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1 
                    hrp.CanCollide = true
                end
            end)
        end
    end
end

HitboxGroup:AddToggle("Hitbox_Enabled", {
    Text = "Enable Hitboxes", Default = false,
    Callback = function(value)
        hitboxEnabled = value
        if not value then
            resetHitboxes()
        end
    end,
})

HitboxGroup:AddSlider("Hitbox_Size", {
    Text = "Hitbox Size", Default = 15, Min = 2, Max = 50, Rounding = 0,
    Callback = function(value) hitboxSize = value end,
})

local hitboxConn = RunService.RenderStepped:Connect(function()
    if hitboxEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                pcall(function()
                    local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                        hrp.Transparency = 0.8
                        hrp.BrickColor = BrickColor.new("White")
                        hrp.Material = Enum.Material.Neon
                        hrp.CanCollide = false
                    end
                end)
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- CONFIGURATION & TELEPORT HANDLER
--------------------------------------------------------------------------------
local ConfigFile = "mspaint_teleport_config.json"

local function SaveConfig()
    if not writefile then return end
    local data = { Toggles = {}, Options = {} }
    
    for name, toggle in pairs(Library.Toggles) do
        data.Toggles[name] = toggle.Value
    end
    
    for name, option in pairs(Library.Options) do
        if typeof(option.Value) == "Color3" then
            data.Options[name] = {option.Value.R, option.Value.G, option.Value.B}
        else
            data.Options[name] = option.Value
        end
    end
    
    pcall(function() writefile(ConfigFile, HttpService:JSONEncode(data)) end)
end

local function LoadConfig()
    if not (readfile and isfile and isfile(ConfigFile)) then return end
    
    local successFile, rawData = pcall(function() return readfile(ConfigFile) end)
    if not successFile then return end
    
    local successJson, data = pcall(function() return HttpService:JSONDecode(rawData) end)
    if not successJson or type(data) ~= "table" then return end
    
    if data.Toggles then
        for name, value in pairs(data.Toggles) do
            if Library.Toggles[name] then Library.Toggles[name]:SetValue(value) end
        end
    end
    
    if data.Options then
        for name, value in pairs(data.Options) do
            if Library.Options[name] then
                if type(value) == "table" and #value >= 3 then
                    Library.Options[name]:SetValueRGB(Color3.new(value[1], value[2], value[3]))
                else
                    Library.Options[name]:SetValue(value)
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(5) do SaveConfig() end
end)

local queue_func = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
LocalPlayer.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Started then
        SaveConfig() 
        if queue_func then
            local scriptUrl = "https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/sniper.lua"
            queue_func(string.format([[
                if not game:IsLoaded() then game.Loaded:Wait() end
                task.wait(1)
                pcall(function() loadstring(game:HttpGet("%s"))() end)
            ]], scriptUrl))
        end
    end
end)

task.delay(0.5, function() LoadConfig() end)

--------------------------------------------------------------------------------
-- SETTINGS TAB & CLEANUP
--------------------------------------------------------------------------------
local SettingsTab = Window:AddTab("Settings", "settings")
local SettingsGroup = SettingsTab:AddLeftGroupbox("General")
SettingsGroup:AddButton({ Text = "Unload Script", Func = function() Library:Unload() end })

Library:OnUnload(function()
    SaveConfig()
    if renderConn then renderConn:Disconnect() end
    if aimbotConn then aimbotConn:Disconnect() end
    if hitboxConn then hitboxConn:Disconnect() end
    resetHitboxes() 
    FOVCircle:Remove()
    for i = 1, #AllLines do AllLines[i]:Remove() end
    table.clear(AllLines)
    table.clear(LineSlots)
end)
