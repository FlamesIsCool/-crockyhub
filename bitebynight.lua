local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local UserInputService  = game:GetService("UserInputService")
local LocalPlayer       = Players.LocalPlayer
local Cam               = workspace.CurrentCamera

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
   Name = "Bite By Night - Crocky Hub",
   Icon = 0, -- Icon in Topbar. Can use Lucide Icons (string) or Roblox Image (number). 0 to use no icon (default).
   LoadingTitle = "Loading...",
   LoadingSubtitle = "by Flames",
   ShowText = "Crocky Hub", -- for mobile users to unhide Rayfield, change if you'd like
   Theme = "Default", -- Check https://docs.sirius.menu/rayfield/configuration/themes

   ToggleUIKeybind = "K", -- The keybind to toggle the UI visibility (string like "K" or Enum.KeyCode)

   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false, -- Prevents Rayfield from emitting warnings when the script has a version mismatch with the interface.

   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil, -- Create a custom folder for your hub/game
      FileName = "Crocky Hub"
   },

   Discord = {
      Enabled = true, -- Prompt the user to join your Discord server if their executor supports it
      Invite = "Yan2XC8HTx", -- The Discord invite code, do not include Discord.gg/. E.g. Discord.gg/ABCD would be ABCD
      RememberJoins = false -- Set this to false to make them join the Discord every time they load it up
   },

   KeySystem = true, -- Set this to true to use our key system
   KeySettings = {
      Title = "CrockyHub - Key",
      Subtitle = "Key System",
      Note = "Join discord for the key", -- Use this to tell the user how to get a key
      FileName = "crockyKey", -- It is recommended to use something unique, as other scripts using Rayfield may overwrite your key file
      SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
      GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
      Key = {"crockykey-2026-67-djethorne"} -- List of keys that the system will accept, can be RAW file links (pastebin, github, etc.) or simple strings ("hello", "key22")
   }
})

local TabMain = Window:CreateTab("Main")

local Config = {
    ESP          = false,
    Boxes        = true,
    Names        = true,
    Distance     = true,
    Tracers      = false,
    StaffDetect  = true,
    GenESP       = false,
    CustomFOV    = 70,
    GenColor     = Color3.fromRGB(0, 255, 100),
    KillerColor  = Color3.fromRGB(255, 40, 40),
    PlayerColor  = Color3.fromRGB(40, 200, 255),
    StaffColor   = Color3.fromRGB(255, 215, 0),
    FullBright   = false,
    InfStamina   = false,
    SnakeGod     = false,
    AutoGenerator = false,
    OriginalLighting = {
        Ambient        = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogEnd         = Lighting.FogEnd,
        ClockTime      = Lighting.ClockTime
    }
}

local STAFF_GROUP_ID = 635601940

local function toggleFullbright(state)
    Config.FullBright = state
    if state then
        Lighting.Ambient, Lighting.OutdoorAmbient = Color3.new(1, 1, 1), Color3.new(1, 1, 1)
        Lighting.FogEnd, Lighting.ClockTime       = 1e5, 12
    else
        local o = Config.OriginalLighting
        Lighting.Ambient        = o.Ambient
        Lighting.OutdoorAmbient = o.OutdoorAmbient
        Lighting.FogEnd         = o.FogEnd
        Lighting.ClockTime      = o.ClockTime
    end
end

-- GUI
TabMain:CreateSection("Visuals / ESP")
TabMain:CreateToggle({ Name = "Enable ESP",       CurrentValue = false, Callback = function(v) Config.ESP = v end })
TabMain:CreateToggle({ Name = "Boxes",            CurrentValue = true,  Callback = function(v) Config.Boxes = v end })
TabMain:CreateToggle({ Name = "Names",            CurrentValue = true,  Callback = function(v) Config.Names = v end })
TabMain:CreateToggle({ Name = "Distance",         CurrentValue = true,  Callback = function(v) Config.Distance = v end })
TabMain:CreateToggle({ Name = "Tracers",          CurrentValue = false, Callback = function(v) Config.Tracers = v end })
TabMain:CreateToggle({ Name = "Highlight Staff",  CurrentValue = true,  Callback = function(v) Config.StaffDetect = v end })
TabMain:CreateToggle({ Name = "Generator ESP",    CurrentValue = false, Callback = function(v) Config.GenESP = v end })
TabMain:CreateToggle({ Name = "FullBright",       CurrentValue = false, Callback = toggleFullbright })
TabMain:CreateSlider({
    Name         = "Custom FOV",
    Range        = { 70, 120 },
    Increment    = 1,
    CurrentValue = 70,
    Callback     = function(v) Config.CustomFOV = v end
})

TabMain:CreateSection("Player Mods")
TabMain:CreateToggle({ Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) Config.InfStamina = v end })

TabMain:CreateSection("Generator")
TabMain:CreateToggle({ Name = "Auto-Complete Generator", CurrentValue = false, Callback = function(v) Config.AutoGenerator = v end })
TabMain:CreateButton({
    Name     = "Instant Finish Current Gen",
    Callback = function()
        pcall(function()
            for _, v in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if v.Name == "GeneratorMain" and v:IsA("LocalScript") then
                    local e = v:FindFirstChild("Event")
                    if e then
                        e:FireServer({ Lever = true, Switches = true, Wires = true })
                    end
                end
            end
        end)
    end
})

TabMain:CreateSection("Snake Minigame")
TabMain:CreateToggle({ Name = "Snake God Mode",  CurrentValue = false, Callback = function(v) Config.SnakeGod = v end })

TabMain:CreateSection("Emotes")
TabMain:CreateButton({
    Name = "Stop Current Emote",
    Callback = function()
        if _G.__current_emote then
            local t, s = _G.__current_emote.track, _G.__current_emote.sound
            if t then pcall(function() t:Stop() end) end
            if s then pcall(function() s:Destroy() end) end
            _G.__current_emote = nil
        end
    end
})

local emotesFolder = ReplicatedStorage:FindFirstChild("Modules")
    and ReplicatedStorage.Modules:FindFirstChild("Emotes")

if emotesFolder then
    for _, em in ipairs(emotesFolder:GetChildren()) do
        if em:IsA("ModuleScript") then
            TabMain:CreateButton({
                Name = em.Name,
                Callback = function()
                    local loop = em:FindFirstChild("Loop")
                    local snd  = em:FindFirstChild("Sound")

                    if _G.__current_emote then
                        local t, s = _G.__current_emote.track, _G.__current_emote.sound
                        if t then pcall(function() t:Stop() end) end
                        if s then pcall(function() s:Destroy() end) end
                    end

                    if loop and LocalPlayer.Character then
                        local hum  = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if hum and root then
                            local track = hum:LoadAnimation(loop)
                            track.Looped = true
                            track:Play()
                            local sound
                            if snd then
                                sound = snd:Clone()
                                sound.Parent = root
                                sound:Play()
                            end
                            _G.__current_emote = { track = track, sound = sound }
                        end
                    end
                end
            })
        end
    end
end

-- Player ESP
local ESP_Cache = {}

local function newESP(plr)
    ESP_Cache[plr] = {
        Box    = Drawing.new("Square"),
        Name   = Drawing.new("Text"),
        Dist   = Drawing.new("Text"),
        Tracer = Drawing.new("Line")
    }
end

local function delESP(plr)
    local t = ESP_Cache[plr]
    if t then
        for _, o in pairs(t) do o:Remove() end
        ESP_Cache[plr] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then newESP(p) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then newESP(p) end end)
Players.PlayerRemoving:Connect(delESP)

RunService.RenderStepped:Connect(function()
    for plr, esp in pairs(ESP_Cache) do
        local char = plr.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")

        if Config.ESP and hrp and hum and hum.Health > 0 then
            local pos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
            if onScreen then
                local dist  = (Cam.CFrame.Position - hrp.Position).Magnitude
                local scale = 1000 / (dist * (Cam.FieldOfView / 100))
                local color = Config.PlayerColor

                if char.Parent and char.Parent.Name == "KILLER" then
                    color = Config.KillerColor
                end
                if Config.StaffDetect then
                    pcall(function()
                        if plr:GetRankInGroup(STAFF_GROUP_ID) > 0 then
                            color = Config.StaffColor
                        end
                    end)
                end

                esp.Box.Visible      = Config.Boxes
                esp.Box.Size         = Vector2.new(scale, scale * 1.5)
                esp.Box.Position     = Vector2.new(pos.X - scale / 2, pos.Y - scale / 1.2)
                esp.Box.Color        = color
                esp.Box.Thickness    = 1.5

                esp.Name.Visible     = Config.Names
                esp.Name.Text        = plr.Name
                esp.Name.Position    = Vector2.new(pos.X, pos.Y - scale / 1.2 - 20)
                esp.Name.Color       = color
                esp.Name.Center      = true
                esp.Name.Size        = 16
                esp.Name.Outline     = true

                esp.Dist.Visible     = Config.Distance
                esp.Dist.Text        = string.format("%dm", dist)
                esp.Dist.Position    = Vector2.new(pos.X, pos.Y + scale / 1.5 + 5)
                esp.Dist.Color       = color
                esp.Dist.Center      = true
                esp.Dist.Size        = 14
                esp.Dist.Outline     = true

                esp.Tracer.Visible   = Config.Tracers
                esp.Tracer.From      = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y)
                esp.Tracer.To        = Vector2.new(pos.X, pos.Y + scale / 1.5)
                esp.Tracer.Color     = color
                esp.Tracer.Thickness = 1.5
            else
                for _, o in pairs(esp) do o.Visible = false end
            end
        else
            for _, o in pairs(esp) do o.Visible = false end
        end
    end
end)

-- Generator ESP
local Gen_Cache = {}

local function registerGen(model)
    if Gen_Cache[model] then return end
    local part = model.PrimaryPart
        or model:FindFirstChildWhichIsA("BasePart")
        or model:FindFirstChild("Main")
        or model:FindFirstChild("GeneratorMain")
    if part then
        Gen_Cache[model] = { Part = part, Text = Drawing.new("Text") }
    end
end

for _, o in ipairs(workspace:GetDescendants()) do
    if o:IsA("Model") and o.Name == "Generator" then registerGen(o) end
end
workspace.DescendantAdded:Connect(function(o)
    if o:IsA("Model") and o.Name == "Generator" then registerGen(o) end
end)

RunService.RenderStepped:Connect(function()
    for model, e in pairs(Gen_Cache) do
        local part = e.Part
        if Config.GenESP and part and part.Parent then
            local pos, onScreen = Cam:WorldToViewportPoint(part.Position)
            if onScreen then
                local d = (Cam.CFrame.Position - part.Position).Magnitude
                e.Text.Visible   = true
                e.Text.Text      = string.format("[Generator]\n%dm", d)
                e.Text.Position  = Vector2.new(pos.X, pos.Y)
                e.Text.Center    = true
                e.Text.Outline   = true
                e.Text.Color     = Config.GenColor
            else
                e.Text.Visible = false
            end
        else
            e.Text.Visible = false
        end
    end
end)

-- Camera FOV
RunService:BindToRenderStep("HubFOV", Enum.RenderPriority.Camera.Value + 1, function()
    if Cam and Cam.FieldOfView ~= Config.CustomFOV then
        Cam.FieldOfView = Config.CustomFOV
    end
end)

-- Infinite Stamina
RunService.Stepped:Connect(function()
    if Config.InfStamina then
        pcall(function()
            LocalPlayer:SetAttribute("Stamina", 100)
            if LocalPlayer.Character then
                LocalPlayer.Character:SetAttribute("Stamina", 100)
            end
            local s = LocalPlayer:FindFirstChild("Stats") or LocalPlayer:FindFirstChild("leaderstats")
            if s and s:FindFirstChild("Stamina") then
                s.Stamina.Value = 100
            end
        end)
    end
end)

-- Snake hacks
local function applySnakeHacks()
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" and rawget(v, "ClassName") == "Game" then
            v.CheckForDeath = function(self)
                if Config.SnakeGod then return false end
                return self:CheckForDeath()
            end
            _G.MaxSnake = function()
                if v.Snake then
                    v.Snake.Length = (v.GridSize * v.GridSize) - 2
                    v:IncrementScore()
                end
            end
        end
    end
end
applySnakeHacks()

-- Auto complete generator
RunService.Heartbeat:Connect(function()
    if Config.AutoGenerator then
        pcall(function()
            for _, v in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
                if v.Name == "GeneratorMain" and v:IsA("LocalScript") then
                    local e = v:FindFirstChild("Event")
                    if e then
                        e:FireServer({ Lever = true, Switches = true, Wires = true })
                    end
                end
            end
        end)
    end
end)

-- Staff notifications
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        pcall(function()
            if p:GetRankInGroup(STAFF_GROUP_ID) > 1 then
                Rayfield:Notify({
                    Title   = "STAFF DETECTED",
                    Content = p.Name .. " is a game admin.",
                    Duration = 8
                })
            end
        end)
    end
end
Players.PlayerAdded:Connect(function(p)
    pcall(function()
        if p:GetRankInGroup(STAFF_GROUP_ID) > 1 then
            Rayfield:Notify({
                Title   = "STAFF DETECTED",
                Content = p.Name .. " joined (admin).",
                Duration = 8
            })
        end
    end)
end)
