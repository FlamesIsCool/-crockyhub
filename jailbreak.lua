local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Bracket = loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/Bracket/main/BracketV32.lua"))()
Bracket:Notification()
Bracket:Notification2()

local Window = Bracket:Window({
    Name = "CrockyHub - Jailbreak",
    Enabled = true,
    Color = Color3.new(1, 0.5, 0.25),
    Size = UDim2.new(0, 560, 0, 540),
    Position = UDim2.new(0.5, -280, 0.5, -270)
})

local PlayerTab = Window:Tab({Name = "Player"})
local EspTab = Window:Tab({Name = "ESP"})

local state = {
    WalkSpeed = 16,
    JumpPower = 50,
    Gravity = Workspace.Gravity,
    FOV = Camera.FieldOfView,
    InfJump = false,
    Noclip = false,
    Fly = false,
    FlySpeed = 75
}

local espState = {
    BoxESP = false,
    Tracers = false,
    TeamCheck = false,
    TeamESP = false,
    NameESP = false,
    Distance = false,
    Arrows = false,
    HealthESP = false,
    Color = Color3.fromRGB(255, 140, 60)
}

local flyDirection = Vector3.zero
local flyBodyVelocity
local flyBodyGyro
local flyConn
local noclipConn
local infJumpConn
local charAddedConn
local espConn

local drawings = {}

local function getCharacter(player)
    return player.Character
end

local function getHumanoid(player)
    local character = getCharacter(player)
    if not character then
        return nil
    end
    return character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(player)
    local character = getCharacter(player)
    if not character then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart")
end

local function applyCharacterStats()
    local humanoid = getHumanoid(LocalPlayer)
    if humanoid then
        humanoid.WalkSpeed = state.WalkSpeed
        humanoid.JumpPower = state.JumpPower
        humanoid.UseJumpPower = true
    end
end

local function stopFly()
    if flyConn then
        flyConn:Disconnect()
        flyConn = nil
    end
    local root = getRootPart(LocalPlayer)
    if root then
        local bv = root:FindFirstChild("CrockyHubFlyVelocity")
        local bg = root:FindFirstChild("CrockyHubFlyGyro")
        if bv then
            bv:Destroy()
        end
        if bg then
            bg:Destroy()
        end
    end
    flyBodyVelocity = nil
    flyBodyGyro = nil
end

local function startFly()
    stopFly()
    local root = getRootPart(LocalPlayer)
    if not root then
        return
    end

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.Name = "CrockyHubFlyGyro"
    flyBodyGyro.P = 9e4
    flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBodyGyro.CFrame = root.CFrame
    flyBodyGyro.Parent = root

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Name = "CrockyHubFlyVelocity"
    flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBodyVelocity.Velocity = Vector3.zero
    flyBodyVelocity.Parent = root

    flyConn = RunService.RenderStepped:Connect(function()
        if not state.Fly then
            return
        end
        local currentRoot = getRootPart(LocalPlayer)
        if not currentRoot or not flyBodyVelocity or not flyBodyGyro then
            return
        end

        local cam = Workspace.CurrentCamera
        local moveVec = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVec += cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVec -= cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVec -= cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVec += cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVec += cam.CFrame.UpVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveVec -= cam.CFrame.UpVector
        end

        flyDirection = moveVec.Magnitude > 0 and moveVec.Unit or Vector3.zero
        flyBodyVelocity.Velocity = flyDirection * state.FlySpeed
        flyBodyGyro.CFrame = cam.CFrame
    end)
end

local function setNoclip(enabled)
    if noclipConn then
        noclipConn:Disconnect()
        noclipConn = nil
    end
    if not enabled then
        return
    end
    noclipConn = RunService.Stepped:Connect(function()
        local character = LocalPlayer.Character
        if not character then
            return
        end
        for _, obj in ipairs(character:GetDescendants()) do
            if obj:IsA("BasePart") then
                obj.CanCollide = false
            end
        end
    end)
end

local function setInfJump(enabled)
    if infJumpConn then
        infJumpConn:Disconnect()
        infJumpConn = nil
    end
    if not enabled then
        return
    end
    infJumpConn = UserInputService.JumpRequest:Connect(function()
        local humanoid = getHumanoid(LocalPlayer)
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function createDrawings()
    return {
        Box = Drawing.new("Square"),
        Tracer = Drawing.new("Line"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        Team = Drawing.new("Text"),
        Arrow = Drawing.new("Triangle")
    }
end

local function hideDrawingSet(set)
    for _, obj in pairs(set) do
        obj.Visible = false
    end
end

local function removeDrawingSet(set)
    for _, obj in pairs(set) do
        obj:Remove()
    end
end

local function getDrawingSet(player)
    if not drawings[player] then
        drawings[player] = createDrawings()
    end
    return drawings[player]
end

local function shouldRenderPlayer(player)
    if player == LocalPlayer then
        return false
    end
    if espState.TeamCheck and player.Team == LocalPlayer.Team then
        return false
    end
    return true
end

local function worldToScreen(pos)
    local point, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(point.X, point.Y), onScreen, point.Z
end

local function renderPlayerESP(player)
    local set = getDrawingSet(player)
    hideDrawingSet(set)

    if not shouldRenderPlayer(player) then
        return
    end

    local character = getCharacter(player)
    local humanoid = getHumanoid(player)
    local root = getRootPart(player)
    local head = character and character:FindFirstChild("Head")
    if not character or not humanoid or humanoid.Health <= 0 or not root or not head then
        return
    end

    local _, headOnScreen = worldToScreen(head.Position + Vector3.new(0, 0.6, 0))
    local rootPos, rootOnScreen, depth = worldToScreen(root.Position)
    if depth <= 0 then
        return
    end

    local color = espState.Color
    local distanceStuds = math.floor((Camera.CFrame.Position - root.Position).Magnitude)

    if headOnScreen and rootOnScreen then
        local sizeY = math.clamp(2400 / depth, 22, 300)
        local sizeX = sizeY * 0.6
        local boxPos = Vector2.new(rootPos.X - sizeX / 2, rootPos.Y - sizeY / 2)

        if espState.BoxESP then
            set.Box.Visible = true
            set.Box.Color = color
            set.Box.Thickness = 2
            set.Box.Filled = false
            set.Box.Transparency = 1
            set.Box.Size = Vector2.new(sizeX, sizeY)
            set.Box.Position = boxPos
        end

        if espState.Tracers then
            set.Tracer.Visible = true
            set.Tracer.Color = color
            set.Tracer.Thickness = 1.5
            set.Tracer.Transparency = 1
            set.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 24)
            set.Tracer.To = Vector2.new(rootPos.X, rootPos.Y + sizeY / 2)
        end

        if espState.NameESP then
            set.Name.Visible = true
            set.Name.Color = color
            set.Name.Size = 13
            set.Name.Center = true
            set.Name.Outline = true
            set.Name.OutlineColor = Color3.new(0, 0, 0)
            set.Name.Text = player.Name
            set.Name.Position = Vector2.new(rootPos.X, boxPos.Y - 16)
        end

        if espState.Distance then
            set.Distance.Visible = true
            set.Distance.Color = color
            set.Distance.Size = 13
            set.Distance.Center = true
            set.Distance.Outline = true
            set.Distance.OutlineColor = Color3.new(0, 0, 0)
            set.Distance.Text = tostring(distanceStuds) .. " studs"
            set.Distance.Position = Vector2.new(rootPos.X, boxPos.Y + sizeY + 2)
        end

        if espState.HealthESP then
            set.Health.Visible = true
            set.Health.Color = color
            set.Health.Size = 13
            set.Health.Center = true
            set.Health.Outline = true
            set.Health.OutlineColor = Color3.new(0, 0, 0)
            set.Health.Text = tostring(math.floor(humanoid.Health)) .. " HP"
            set.Health.Position = Vector2.new(rootPos.X, boxPos.Y + sizeY + 16)
        end

        if espState.TeamESP then
            local teamName = player.Team and player.Team.Name or "No Team"
            set.Team.Visible = true
            set.Team.Color = color
            set.Team.Size = 13
            set.Team.Center = true
            set.Team.Outline = true
            set.Team.OutlineColor = Color3.new(0, 0, 0)
            set.Team.Text = teamName
            set.Team.Position = Vector2.new(rootPos.X, boxPos.Y - 30)
        end
    elseif espState.Arrows then
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local dir3 = (root.Position - Camera.CFrame.Position).Unit
        local camSpace = Camera.CFrame:VectorToObjectSpace(dir3)
        local dir2 = Vector2.new(camSpace.X, -camSpace.Y)
        if dir2.Magnitude > 0 then
            local norm = dir2.Unit
            local radius = math.min(Camera.ViewportSize.X, Camera.ViewportSize.Y) * 0.35
            local tip = center + norm * radius
            local perp = Vector2.new(-norm.Y, norm.X)
            local left = tip - norm * 16 + perp * 10
            local right = tip - norm * 16 - perp * 10

            set.Arrow.Visible = true
            set.Arrow.Color = color
            set.Arrow.Filled = true
            set.Arrow.Transparency = 1
            set.Arrow.PointA = tip
            set.Arrow.PointB = left
            set.Arrow.PointC = right
        end
    end
end

local function setESPEnabled(enabled)
    if espConn then
        espConn:Disconnect()
        espConn = nil
    end

    if not enabled then
        for _, set in pairs(drawings) do
            hideDrawingSet(set)
        end
        return
    end

    espConn = RunService.RenderStepped:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            renderPlayerESP(player)
        end
    end)
end

local function refreshESP()
    local enabled = espState.BoxESP or espState.Tracers or espState.TeamESP or espState.NameESP or espState.Distance or espState.Arrows or espState.HealthESP
    setESPEnabled(enabled)
end

Players.PlayerRemoving:Connect(function(player)
    local set = drawings[player]
    if set then
        removeDrawingSet(set)
        drawings[player] = nil
    end
end)

charAddedConn = LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    applyCharacterStats()
    if state.Fly then
        startFly()
    end
end)

PlayerTab:Divider({Text = "Movement", Side = "Left"})

PlayerTab:Slider({
    Name = "WalkSpeed",
    Side = "Left",
    Min = 0,
    Max = 300,
    Value = state.WalkSpeed,
    Precise = 0,
    Callback = function(value)
        state.WalkSpeed = value
        local humanoid = getHumanoid(LocalPlayer)
        if humanoid then
            humanoid.WalkSpeed = value
        end
    end
})

PlayerTab:Slider({
    Name = "JumpPower",
    Side = "Left",
    Min = 0,
    Max = 300,
    Value = state.JumpPower,
    Precise = 0,
    Callback = function(value)
        state.JumpPower = value
        local humanoid = getHumanoid(LocalPlayer)
        if humanoid then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = value
        end
    end
})

PlayerTab:Slider({
    Name = "Gravity",
    Side = "Left",
    Min = 0,
    Max = 500,
    Value = state.Gravity,
    Precise = 0,
    Callback = function(value)
        state.Gravity = value
        Workspace.Gravity = value
    end
})

PlayerTab:Slider({
    Name = "FOV",
    Side = "Left",
    Min = 40,
    Max = 120,
    Value = state.FOV,
    Precise = 0,
    Callback = function(value)
        state.FOV = value
        Workspace.CurrentCamera.FieldOfView = value
    end
})

PlayerTab:Toggle({
    Name = "InfJump",
    Side = "Left",
    Value = false,
    Callback = function(enabled)
        state.InfJump = enabled
        setInfJump(enabled)
    end
})

PlayerTab:Toggle({
    Name = "Noclip",
    Side = "Left",
    Value = false,
    Callback = function(enabled)
        state.Noclip = enabled
        setNoclip(enabled)
    end
})

PlayerTab:Divider({Text = "Flight", Side = "Right"})

PlayerTab:Toggle({
    Name = "Fly",
    Side = "Right",
    Value = false,
    Callback = function(enabled)
        state.Fly = enabled
        if enabled then
            startFly()
        else
            stopFly()
        end
    end
})

PlayerTab:Slider({
    Name = "Fly Speed",
    Side = "Right",
    Min = 10,
    Max = 400,
    Value = state.FlySpeed,
    Precise = 0,
    Callback = function(value)
        state.FlySpeed = value
    end
})

EspTab:Divider({Text = "Visuals", Side = "Left"})

EspTab:Toggle({
    Name = "Box ESP",
    Side = "Left",
    Value = false,
    Callback = function(enabled)
        espState.BoxESP = enabled
        refreshESP()
    end
})

EspTab:Toggle({
    Name = "Tracers",
    Side = "Left",
    Value = false,
    Callback = function(enabled)
        espState.Tracers = enabled
        refreshESP()
    end
})

EspTab:Toggle({
    Name = "Team Check",
    Side = "Left",
    Value = false,
    Callback = function(enabled)
        espState.TeamCheck = enabled
    end
})

EspTab:Toggle({
    Name = "Team ESP",
    Side = "Left",
    Value = false,
    Callback = function(enabled)
        espState.TeamESP = enabled
        refreshESP()
    end
})

EspTab:Toggle({
    Name = "Name ESP",
    Side = "Left",
    Value = false,
    Callback = function(enabled)
        espState.NameESP = enabled
        refreshESP()
    end
})

EspTab:Toggle({
    Name = "Distance",
    Side = "Right",
    Value = false,
    Callback = function(enabled)
        espState.Distance = enabled
        refreshESP()
    end
})

EspTab:Toggle({
    Name = "Arrows",
    Side = "Right",
    Value = false,
    Callback = function(enabled)
        espState.Arrows = enabled
        refreshESP()
    end
})

EspTab:Toggle({
    Name = "Health ESP",
    Side = "Right",
    Value = false,
    Callback = function(enabled)
        espState.HealthESP = enabled
        refreshESP()
    end
})

EspTab:Colorpicker({
    Name = "ESP Color",
    Side = "Right",
    Color = espState.Color,
    Callback = function(color)
        espState.Color = color
    end
})

applyCharacterStats()

local function cleanup()
    stopFly()
    setNoclip(false)
    setInfJump(false)
    setESPEnabled(false)
    for _, set in pairs(drawings) do
        removeDrawingSet(set)
    end
    drawings = {}
    if charAddedConn then
        charAddedConn:Disconnect()
        charAddedConn = nil
    end
end

Window.OnClose = cleanup
