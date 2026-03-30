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
    Size = UDim2.new(0, 520, 0, 520),
    Position = UDim2.new(0.5, -260, 0.5, -260)
})

local PlayerTab = Window:Tab({Name = "Player"})

local state = {
    WalkSpeed = 16,
    JumpPower = 50,
    Gravity = Workspace.Gravity,
    FOV = Camera.FieldOfView,
    InfJump = false,
    Noclip = false,
    Fly = false,
    FlySpeed = 75,
    VehicleFly = false,
    VehicleFlySpeed = 110
}

local flyDirection = Vector3.zero
local flyBodyVelocity
local flyBodyGyro
local flyConn
local noclipConn
local infJumpConn
local vehicleFlyConn
local charAddedConn

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHumanoid()
    local character = getCharacter()
    return character:FindFirstChildOfClass("Humanoid")
end

local function applyCharacterStats()
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = state.WalkSpeed
        humanoid.JumpPower = state.JumpPower
        humanoid.UseJumpPower = true
    end
end

local function getRootPart()
    local character = getCharacter()
    return character:FindFirstChild("HumanoidRootPart")
end

local function stopFly()
    if flyConn then
        flyConn:Disconnect()
        flyConn = nil
    end
    local root = getRootPart()
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
    local root = getRootPart()
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
        local currentRoot = getRootPart()
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
        local humanoid = getHumanoid()
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

local function getVehicleSeat()
    local character = LocalPlayer.Character
    if not character then
        return nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return nil
    end
    local seatPart = humanoid.SeatPart
    if seatPart and (seatPart:IsA("VehicleSeat") or seatPart:IsA("Seat")) then
        return seatPart
    end
    return nil
end

local function setVehicleFly(enabled)
    if vehicleFlyConn then
        vehicleFlyConn:Disconnect()
        vehicleFlyConn = nil
    end
    if not enabled then
        return
    end

    vehicleFlyConn = RunService.Heartbeat:Connect(function(dt)
        local seat = getVehicleSeat()
        if not seat then
            return
        end
        local assembly = seat.AssemblyRootPart or seat
        if not assembly then
            return
        end

        local cam = Workspace.CurrentCamera
        local direction = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            direction += cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            direction -= cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            direction -= cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            direction += cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            direction += cam.CFrame.UpVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction -= cam.CFrame.UpVector
        end

        if direction.Magnitude > 0 then
            assembly.AssemblyLinearVelocity = direction.Unit * state.VehicleFlySpeed
        else
            assembly.AssemblyLinearVelocity = Vector3.zero
        end
        assembly.AssemblyAngularVelocity = Vector3.zero

        local move = direction.Magnitude > 0 and direction.Unit * state.VehicleFlySpeed * dt or Vector3.zero
        assembly.CFrame = CFrame.new(assembly.Position + move, assembly.Position + cam.CFrame.LookVector)
    end)
end

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
        local humanoid = getHumanoid()
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
        local humanoid = getHumanoid()
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

PlayerTab:Toggle({
    Name = "Vehicle Fly",
    Side = "Right",
    Value = false,
    Callback = function(enabled)
        state.VehicleFly = enabled
        setVehicleFly(enabled)
    end
})

PlayerTab:Slider({
    Name = "Vehicle Fly Speed",
    Side = "Right",
    Min = 10,
    Max = 500,
    Value = state.VehicleFlySpeed,
    Precise = 0,
    Callback = function(value)
        state.VehicleFlySpeed = value
    end
})

applyCharacterStats()

local function cleanup()
    stopFly()
    setNoclip(false)
    setInfJump(false)
    setVehicleFly(false)
    if charAddedConn then
        charAddedConn:Disconnect()
        charAddedConn = nil
    end
end

Window.OnClose = cleanup
