-- Prevent multiple windows
if getgenv().MSPaintLoaded then return end
getgenv().MSPaintLoaded = true

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
MainGroup:AddToggle("ESP_Enabled", {Text="Enable ESP"})
MainGroup:AddToggle("ESP_Tracers", {Text="Enable Tracers"})
OptGroup:AddLabel("Box Color"):AddColorPicker("Box_Color", {Default = Color3.fromRGB(255, 255, 255)})

--------------------------------------------------------------------------------
-- TAB: COMBAT
--------------------------------------------------------------------------------
local CombatTab = Window:AddTab("Combat", "swords")
local HitGroup = CombatTab:AddLeftGroupbox("Hitboxes")
local LockGroup = CombatTab:AddRightGroupbox("Camera Lock")
HitGroup:AddToggle("Hitbox_Enabled", {Text="Enable Hitboxes", Callback = function(v) _G.Disabled = v end})
LockGroup:AddToggle("CamLock_Enabled", {Text = "Enable Cam Lock"})

--------------------------------------------------------------------------------
-- TAB: SOCIALS (Force Rendered)
--------------------------------------------------------------------------------
local SocialTab = Window:AddTab("Socials", "heart")
local LinkGroup = SocialTab:AddLeftGroupbox("Copy Links")
local LogoGroup = SocialTab:AddRightGroupbox("Logos")

LinkGroup:AddButton({Text = "Copy Discord", Func = function() setclipboard("https://discord.gg/saXzuhsFbj"); Library:Notify("Copied Discord!", 3) end})
LinkGroup:AddButton({Text = "Copy TikTok", Func = function() setclipboard("https://www.tiktok.com/@1l1l11111l1"); Library:Notify("Copied TikTok!", 3) end})

-- Explicitly force the creation of the ImageLabels
local DiscordImg = Instance.new("ImageLabel", LogoGroup.Groupbox)
DiscordImg.Size = UDim2.new(0, 100, 0, 100)
DiscordImg.Image = "https://raw.githubusercontent.com/s8lkkkkk/dwja9dj-9aw80wd/refs/heads/main/Screenshot%202026-07-04%20222940-Photoroom.png"
DiscordImg.BackgroundTransparency = 1

--------------------------------------------------------------------------------
-- TAB: CONFIG (Force Rendered)
--------------------------------------------------------------------------------
local ConfigTab = Window:AddTab("Config", "file-text")
local ManageGroup = ConfigTab:AddLeftGroupbox("Management")
ManageGroup:AddButton({Text="Save Settings", Func=function() end})
ManageGroup:AddButton({Text="Load Settings", Func=function() end})
