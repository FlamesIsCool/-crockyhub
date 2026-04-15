local discordInvite = "https://discord.com/invite/Yan2XC8HTx"

local http_request = (syn and syn.request) or (http and http.request) or request
if http_request then
    http_request({
        Url = "http://127.0.0.1:6463/rpc?v=1",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["Origin"] = "https://discord.com"
        },
        Body = game:GetService("HttpService"):JSONEncode({
            cmd = "INVITE_BROWSER",
            args = {code = string.match(discordInvite, "discord%.com/invite/(%w+)")},
            nonce = game:GetService("HttpService"):GenerateGUID(false)
        })
    })
else
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Executor Not Supported",
        Text = "Join manually: "..discordInvite,
        Duration = 5
    })
end


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
   Icon = 0,
   LoadingTitle = "Loading...",
   LoadingSubtitle = "by Flames",
   ShowText = "Crocky Hub",
   Theme = "Default",
   ToggleUIKeybind = "K",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "Crocky Hub"
   },
   Discord = {
      Enabled = true,
      Invite = "Yan2XC8HTx",
      RememberJoins = false
   },
   KeySystem = false,
   KeySettings = {
      Title = "CrockyHub - Key",
      Subtitle = "Key System",
      Note = "Join discord for the key",
      FileName = "crockyKey",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"crockykey-2026-67-djethorne"}
   }
})
local TabMain = Window:CreateTab("Main")
local CollectionService = game:GetService("CollectionService")
local TweenService     = game:GetService("TweenService")
local SoundService     = game:GetService("SoundService")
local Config = {
    ESP          = false,
    Boxes        = true,
    Names        = true,
    Distance     = true,
    Tracers      = false,
    StaffDetect  = true,
    GenESP       = false,
    BatteryESP    = false,
    CustomFOV    = 70,
    GenColor     = Color3.fromRGB(0, 255, 100),
    BatteryColor  = Color3.fromRGB(255, 255, 0),
    KillerColor  = Color3.fromRGB(255, 40, 40),
    PlayerColor  = Color3.fromRGB(40, 200, 255),
    StaffColor   = Color3.fromRGB(255, 215, 0),
    FullBright   = false,
    InfStamina   = false,
    SnakeGod     = false,
    AutoGenerator = false,
    AntiStun      = false,
    AntiBlind     = false,
    AntiDeaf      = false,
    AntiFlashbang = false,
    KillerAlert   = false,
    KillerAlertDist = 60,
    Noclip        = false,
    AutoHeal      = false,
    AntiKillAnim  = false,
    GameInfoHUD   = false,
    AntiKick      = true,
    OriginalLighting = {
        Ambient        = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogEnd         = Lighting.FogEnd,
        ClockTime      = Lighting.ClockTime
    }
}
local STAFF_GROUP_ID = 635601940
if hookmetamethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if Config.AntiKick then
            if method == "Kick" and (typeof(self) == "Instance" and self:IsA("Player")) then
                return
            end
        end
        return oldNamecall(self, ...)
    end))
end
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
TabMain:CreateSection("Visuals / ESP")
TabMain:CreateToggle({ Name = "Enable ESP",       CurrentValue = false, Callback = function(v) Config.ESP = v end })
TabMain:CreateToggle({ Name = "Boxes",            CurrentValue = true,  Callback = function(v) Config.Boxes = v end })
TabMain:CreateToggle({ Name = "Names",            CurrentValue = true,  Callback = function(v) Config.Names = v end })
TabMain:CreateToggle({ Name = "Distance",         CurrentValue = true,  Callback = function(v) Config.Distance = v end })
TabMain:CreateToggle({ Name = "Tracers",          CurrentValue = false, Callback = function(v) Config.Tracers = v end })
TabMain:CreateToggle({ Name = "Highlight Staff",  CurrentValue = true,  Callback = function(v) Config.StaffDetect = v end })
TabMain:CreateToggle({ Name = "Generator ESP",    CurrentValue = false, Callback = function(v) Config.GenESP = v end })
TabMain:CreateToggle({
    Name = "Battery ESP",
    CurrentValue = false,
    Callback = function(v)
        Config.BatteryESP = v
    end
})
TabMain:CreateToggle({ Name = "FullBright",       CurrentValue = false, Callback = toggleFullbright })
TabMain:CreateSlider({
    Name         = "Custom FOV",
    Range        = { 70, 120 },
    Increment    = 1,
    CurrentValue = 70,
    Callback     = function(v) 
        Config.CustomFOV = v 
        workspace.CurrentCamera.FieldOfView = v
    end
})
TabMain:CreateSection("Player Mods")
TabMain:CreateToggle({ Name = "Infinite Stamina", CurrentValue = false, Callback = function(v) Config.InfStamina = v end })
TabMain:CreateToggle({
    Name = "Anti-Stun / Anti-Trap",
    CurrentValue = false,
    Callback = function(v) Config.AntiStun = v end
})
TabMain:CreateToggle({
    Name = "Anti-Blindness",
    CurrentValue = false,
    Callback = function(v) Config.AntiBlind = v end
})
TabMain:CreateToggle({
    Name = "Anti-Deafness",
    CurrentValue = false,
    Callback = function(v) Config.AntiDeaf = v end
})
TabMain:CreateToggle({
    Name = "Anti-Flashbang",
    CurrentValue = false,
    Callback = function(v) Config.AntiFlashbang = v end
})
TabMain:CreateToggle({
    Name = "Anti-Kill Animation",
    CurrentValue = false,
    Callback = function(v) Config.AntiKillAnim = v end
})
TabMain:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v) Config.Noclip = v end
})
TabMain:CreateToggle({
    Name = "Auto-Heal (Medkit Spam)",
    CurrentValue = false,
    Callback = function(v) Config.AutoHeal = v end
})
TabMain:CreateToggle({
    Name = "Anti-Kick (Block Server Kick)",
    CurrentValue = true,
    Callback = function(v) Config.AntiKick = v end
})
TabMain:CreateSection("Generator")
TabMain:CreateToggle({ Name = "Auto-Complete Generator", CurrentValue = false, Callback = function(v) Config.AutoGenerator = v end })
TabMain:CreateButton({
    Name     = "Instant Finish Current Gen",
    Callback = function()
        pcall(function()
            local fired = false
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("RemoteEvent") and desc.Name == "Event" then
                            desc:FireServer({["Lever"]=true,["Switches"]=true,["Wires"]=true})
                            fired = true
                        end
                    end
                end
            end
            if fired then
                Rayfield:Notify({Title="Generator",Content="Sent completion!",Duration=2})
            else
                Rayfield:Notify({Title="Generator",Content="No generator GUI found. Walk up to one first.",Duration=3})
            end
        end)
    end
})
TabMain:CreateSection("Snake Minigame")
TabMain:CreateToggle({
    Name = "Snake God Mode",
    CurrentValue = false,
    Callback = function(v)
        Config.SnakeGod = v
    end
})
TabMain:CreateSection("Killer Alert")
TabMain:CreateToggle({
    Name = "Killer Proximity Alert",
    CurrentValue = false,
    Callback = function(v) Config.KillerAlert = v end
})
TabMain:CreateSlider({
    Name         = "Alert Distance",
    Range        = { 20, 150 },
    Increment    = 5,
    CurrentValue = 60,
    Callback     = function(v)
        Config.KillerAlertDist = v
    end
})
TabMain:CreateSection("Game Info")
TabMain:CreateToggle({
    Name = "Show Game Info HUD",
    CurrentValue = false,
    Callback = function(v)
        Config.GameInfoHUD = v
        if _G.__gameInfoGui then
            _G.__gameInfoGui.Enabled = v
        end
    end
})
TabMain:CreateButton({
    Name = "Print All Player Roles",
    Callback = function()
        local alive = workspace:FindFirstChild("PLAYERS") and workspace.PLAYERS:FindFirstChild("ALIVE")
        local killer = workspace:FindFirstChild("PLAYERS") and workspace.PLAYERS:FindFirstChild("KILLER")
        local msg = "== Player Roles ==\n"
        if killer then
            for _, c in ipairs(killer:GetChildren()) do
                msg = msg .. "[KILLER] " .. c.Name .. "\n"
            end
        end
        if alive then
            for _, c in ipairs(alive:GetChildren()) do
                msg = msg .. "[ALIVE] " .. c.Name .. "\n"
            end
        end
        Rayfield:Notify({ Title = "Player Roles", Content = msg, Duration = 10 })
    end
})
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
local Gen_Cache = {}
local function registerGen(model)
    if Gen_Cache[model] then return end
    local part
    if model:IsA("BasePart") then
        part = model
    else
        part = model.PrimaryPart
            or model:FindFirstChildWhichIsA("BasePart")
            or model:FindFirstChild("Main")
            or model:FindFirstChild("GeneratorMain")
    end
    if part then
        Gen_Cache[model] = { Part = part, Text = Drawing.new("Text") }
    end
end
local function scanForGenerators()
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Model") and o.Name == "Generator" then
            registerGen(o)
        end
        if o.Name == "Generators" and o:IsA("Folder") or (o.Name == "Generators" and o:IsA("Model")) then
            for _, child in ipairs(o:GetChildren()) do
                registerGen(child)
            end
        end
    end
end
scanForGenerators()
workspace.DescendantAdded:Connect(function(o)
    if o:IsA("Model") and o.Name == "Generator" then
        registerGen(o)
    end
    if o.Name == "Generators" then
        task.wait(1)
        for _, child in ipairs(o:GetChildren()) do
            registerGen(child)
        end
    end
    if o.Parent and o.Parent.Name == "Generators" then
        registerGen(o)
    end
end)
task.spawn(function()
    while task.wait(5) do
        scanForGenerators()
    end
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
local Battery_Cache = {}
local function registerBattery(obj)
    if Battery_Cache[obj] then return end
    if obj:IsA("MeshPart") and obj.Name == "Battery" then
        Battery_Cache[obj] = { Part = obj, Text = Drawing.new("Text") }
    end
end
for _, o in ipairs(workspace:GetDescendants()) do
    registerBattery(o)
end
workspace.DescendantAdded:Connect(function(o)
    registerBattery(o)
end)
RunService.RenderStepped:Connect(function()
    for obj, e in pairs(Battery_Cache) do
        if Config.BatteryESP and obj and obj.Parent then
            local pos, onScreen = Cam:WorldToViewportPoint(obj.Position)
            if onScreen then
                local d = (Cam.CFrame.Position - obj.Position).Magnitude
                e.Text.Visible   = true
                e.Text.Text      = string.format("[Battery]\n%dm", d)
                e.Text.Position  = Vector2.new(pos.X, pos.Y)
                e.Text.Center    = true
                e.Text.Outline   = true
                e.Text.Color     = Config.BatteryColor
                e.Text.Size      = 14
            else
                e.Text.Visible = false
            end
        else
            e.Text.Visible = false
            if not obj.Parent then
                e.Text:Remove()
                Battery_Cache[obj] = nil
            end
        end
    end
end)
RunService:BindToRenderStep("HubFOV", Enum.RenderPriority.Last.Value, function()
    if Cam then
        Cam.FieldOfView = Config.CustomFOV
    end
end)
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
local function applySnakeHacks()
    local function hookGames()
        for _, t in ipairs(getgc(true)) do
            if type(t) == "table"
               and rawget(t, "ClassName") == "Game"
               and rawget(t, "CheckForDeath")
               and not t._GodHooked
            then
                local original = t.CheckForDeath
                t.CheckForDeath = newcclosure(function(self, ...)
                    if Config.SnakeGod then
                        return false
                    end
                    return original(self, ...)
                end)
                t._GodHooked = true
            end
        end
    end
    hookGames()
    task.spawn(function()
        while true do
            hookGames()
            task.wait(1)
        end
    end)
end
applySnakeHacks()
local _lastAutoGen = 0
RunService.Heartbeat:Connect(function()
    if Config.AutoGenerator and (tick() - _lastAutoGen) > 0.5 then
        _lastAutoGen = tick()
        pcall(function()
            for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    for _, desc in ipairs(gui:GetDescendants()) do
                        if desc:IsA("RemoteEvent") and desc.Name == "Event" then
                            pcall(function()
                                desc:FireServer({["Lever"]=true,["Switches"]=true,["Wires"]=true})
                            end)
                        end
                    end
                end
            end
        end)
    end
end)
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
RunService.Stepped:Connect(function()
    if Config.AntiStun and LocalPlayer.Character then
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            if char:GetAttribute("Stun") == true then
                char:SetAttribute("Stun", false)
            end
            for _, tag in ipairs({"CantMove", "StopAnim", "KillAnims", "Trapped", "Stunned", "Grabbed"}) do
                if CollectionService:HasTag(char, tag) then
                    CollectionService:RemoveTag(char, tag)
                end
                if hum and CollectionService:HasTag(hum, tag) then
                    CollectionService:RemoveTag(hum, tag)
                end
            end
            if hum then
                if hum.PlatformStand then
                    hum.PlatformStand = false
                end
                if hum:GetState() == Enum.HumanoidStateType.FallingDown
                   or hum:GetState() == Enum.HumanoidStateType.Ragdoll then
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end
        end)
    end
end)
RunService.Stepped:Connect(function()
    pcall(function()
        if Config.AntiBlind then
            if Lighting.FogEnd < 500 then
                Lighting.FogEnd = 99999
            end
            local atm = Lighting:FindFirstChildOfClass("Atmosphere")
            if not atm then
                for _, child in ipairs(workspace:GetDescendants()) do
                    if child:IsA("Atmosphere") and child.Parent ~= Lighting then
                        child.Parent = Lighting
                        break
                    end
                end
            end
            local blindSfx = workspace:FindFirstChild("BlindnessSFX")
            if blindSfx and blindSfx.Volume > 0 then
                blindSfx.Volume = 0
            end
        end
        if Config.AntiDeaf then
            for _, sg in ipairs(SoundService:GetChildren()) do
                if sg:IsA("SoundGroup") then
                    for _, eq in ipairs(sg:GetChildren()) do
                        if eq:IsA("EqualizerSoundEffect") then
                            eq:Destroy()
                        end
                    end
                end
            end
        end
        if Config.AntiFlashbang then
            for _, eff in ipairs(Lighting:GetChildren()) do
                if eff:IsA("ColorCorrectionEffect") and (eff.Brightness > 0.3 or eff.Contrast > 0.3) then
                    eff:Destroy()
                end
            end
        end
    end)
end)
RunService.Stepped:Connect(function()
    if Config.AntiKillAnim and LocalPlayer.Character then
        pcall(function()
            local char = LocalPlayer.Character
            for _, tag in ipairs({"KillAnims", "KillCam", "Grabbed"}) do
                if CollectionService:HasTag(char, tag) then
                    CollectionService:RemoveTag(char, tag)
                end
            end
            if Cam.CameraSubject ~= char:FindFirstChildOfClass("Humanoid") then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    Cam.CameraSubject = hum
                end
            end
        end)
    end
end)
RunService.Stepped:Connect(function()
    if Config.Noclip and LocalPlayer.Character then
        pcall(function()
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
end)
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoHeal and LocalPlayer.Character then
            pcall(function()
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hum or not hrp or hum.Health >= hum.MaxHealth then return end
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and obj.Enabled then
                        local promptPart = obj.Parent
                        if promptPart and promptPart:IsA("BasePart") then
                            local dist = (hrp.Position - promptPart.Position).Magnitude
                            local isGen = false
                            local ancestor = promptPart:FindFirstAncestorOfClass("Model")
                            if ancestor and ancestor.Name == "Generator" then
                                isGen = true
                            end
                            if dist <= obj.MaxActivationDistance + 2 and not isGen then
                                local txt = string.lower(obj.ObjectText .. obj.ActionText .. (promptPart.Name or ""))
                                if string.find(txt, "heal") or string.find(txt, "medkit")
                                   or string.find(txt, "bandage") or string.find(txt, "health")
                                   or string.find(txt, "pick") or string.find(txt, "use")
                                   or string.find(txt, "grab") or string.find(txt, "take") then
                                    fireproximityprompt(obj)
                                end
                            end
                        end
                    end
                end
                pcall(function()
                    hum.Health = hum.MaxHealth
                end)
            end)
        end
    end
end)
local _lastKillerAlert = 0
task.spawn(function()
    while task.wait(0.3) do
        if Config.KillerAlert and LocalPlayer.Character then
            pcall(function()
                local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local killerFolder = workspace:FindFirstChild("PLAYERS") and workspace.PLAYERS:FindFirstChild("KILLER")
                if killerFolder then
                    for _, killer in ipairs(killerFolder:GetChildren()) do
                        local khrp = killer:FindFirstChild("HumanoidRootPart")
                        if khrp then
                            local dist = (hrp.Position - khrp.Position).Magnitude
                            if dist < Config.KillerAlertDist and (tick() - _lastKillerAlert) > 3 then
                                _lastKillerAlert = tick()
                                Rayfield:Notify({
                                    Title   = "KILLER NEARBY!",
                                    Content = string.format("%s is %dm away!", killer.Name, math.floor(dist)),
                                    Duration = 3
                                })
                            end
                        end
                    end
                end
            end)
        end
    end
end)
task.spawn(function()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CrockyHubGameInfo"
    gui.ResetOnSpawn = false
    gui.Enabled = Config.GameInfoHUD
    gui.Parent = LocalPlayer.PlayerGui
    _G.__gameInfoGui = gui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 130)
    frame.Position = UDim2.new(0, 10, 0.4, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, -10)
    label.Position = UDim2.new(0, 5, 0, 5)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 13
    label.Font = Enum.Font.RobotoMono
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.RichText = true
    label.Parent = frame
    while task.wait(0.5) do
        gui.Enabled = Config.GameInfoHUD
        if Config.GameInfoHUD then
            pcall(function()
                local gameF = workspace:FindFirstChild("GAME")
                local timer = gameF and gameF:FindFirstChild("TIMER") and gameF.TIMER.Value or "?"
                local lms = gameF and gameF:FindFirstChild("LMS") and gameF.LMS.Value or false
                local aliveCount = 0
                local killerName = "None"
                local playersF = workspace:FindFirstChild("PLAYERS")
                if playersF then
                    local aliveF = playersF:FindFirstChild("ALIVE")
                    if aliveF then aliveCount = #aliveF:GetChildren() end
                    local killerF = playersF:FindFirstChild("KILLER")
                    if killerF and #killerF:GetChildren() > 0 then
                        killerName = killerF:GetChildren()[1].Name
                    end
                end
                local team = LocalPlayer:GetAttribute("TEAM") or "?"
                local hp = "?"
                if LocalPlayer.Character then
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hp = math.floor(hum.Health) .. "/" .. hum.MaxHealth end
                end
                label.Text = string.format(
                    "<b>Crocky Hub Info</b>\n" ..
                    "Timer: <font color='#ffcc00'>%s</font>\n" ..
                    "LMS: <font color='#ff5555'>%s</font>\n" ..
                    "Alive: <font color='#55ff55'>%d</font>\n" ..
                    "Killer: <font color='#ff4040'>%s</font>\n" ..
                    "Team: <font color='#40c8ff'>%s</font>\n" ..
                    "HP: <font color='#55ff55'>%s</font>",
                    tostring(timer), tostring(lms), aliveCount, killerName, team, hp
                )
            end)
        end
    end
end)
