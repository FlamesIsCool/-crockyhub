local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local Events = ReplicatedStorage:WaitForChild("Event")
local RaceEvents = Events:WaitForChild("Races")
local RemoteEvents = Events:WaitForChild("RemoteEvents")

local CheckRemote = RaceEvents:WaitForChild("Check")
local LeaveRace = RaceEvents:WaitForChild("LeaveRace")
local RaceStart = RaceEvents:WaitForChild("RaceStart")
local RaceFinished = RaceEvents:WaitForChild("RaceFinished")
local RaceLoadStart = RaceEvents:WaitForChild("RaceLoadStart")
local RaceLeft = RaceEvents:WaitForChild("RaceLeft")
local GoToLastCheckpoint = RaceEvents:WaitForChild("GoToLastCheckpoint")

local ClaimDrivingOffline = RemoteEvents:WaitForChild("ClaimDrivingOffline")

local StorageFolder = ReplicatedStorage:WaitForChild("Storage")
local RaceStorage = StorageFolder:WaitForChild("RaceStorage")
local RaceTeleports = StorageFolder:WaitForChild("RaceTeleports")

local CONFIG = {
    SelectedRace = "Highway Race",
    CheckpointDelay = 0.1,
    LoopDelay = 5,
    ClaimOfflineRewards = true,
    AntiAFK = true,
    TeleportHeightOffset = 0,
    TweenSpeed = 300,
}

local State = {
    Running = false,
    InRace = false,
    CurrentRaceName = nil,
    RacesCompleted = 0,
    TotalEarned = 0,
    StartTime = 0,
}

local RaceState = {
    Session = 0,
    Queueing = false,
    Started = false,
    ActiveRaceName = nil,
    StartServerTime = 0,
    StartedSession = 0,
    FinishedSession = 0,
    CancelledSession = 0,
    RewardAmount = 0,
}

local RaceRewards = {
    ["Drag Race"] = 3750,
    ["Beach Dash"] = 5750,
    ["Tropical Dash"] = 8000,
    ["Boat Race"] = 10000,
    ["Offroad Race"] = 14500,
    ["Air Race"] = 13500,
    ["Desert Race"] = 11500,
    ["Karting Race"] = 20000,
    ["Highway Race"] = 20000,
    ["Around The Map"] = 27500,
    ["Snowflake Circuit"] = 28500,
    ["Mountain Dash"] = 32000,
    ["Frozen Lake"] = 32000,
    ["Circuit Race"] = 40000,
    ["Miami City Circuit"] = 41000,
    ["Circuit Moto Race"] = 42000,
}

local RaceLaps = {
    ["Snowflake Circuit"] = 2,
    ["Circuit Race"] = 2,
    ["Circuit Moto Race"] = 2,
    ["Frozen Lake"] = 2,
}

local RaceTimeouts = {
    ["Drag Race"] = 45,
    ["Beach Dash"] = 45,
    ["Tropical Dash"] = 55,
    ["Boat Race"] = 100,
    ["Desert Race"] = 110,
    ["Highway Race"] = 120,
    ["Karting Race"] = 120,
    ["Offroad Race"] = 135,
    ["Around The Map"] = 140,
    ["Air Race"] = 145,
    ["Snowflake Circuit"] = 160,
    ["Mountain Dash"] = 160,
    ["Frozen Lake"] = 180,
    ["Circuit Race"] = 200,
    ["Miami City Circuit"] = 200,
    ["Circuit Moto Race"] = 200,
}

local RaceOptions = {
    "Highway Race",
    "Circuit Moto Race",
    "Miami City Circuit",
    "Circuit Race",
    "Frozen Lake",
    "Mountain Dash",
    "Snowflake Circuit",
    "Around The Map",
    "Karting Race",
    "Offroad Race",
    "Air Race",
    "Desert Race",
    "Boat Race",
    "Tropical Dash",
    "Beach Dash",
    "Drag Race",
}

local function AddCommas(num)
    local formatted = tostring(math.floor(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return formatted
end

local function FormatTime(seconds)
    local hrs = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d:%02d", hrs, mins, secs)
end

local function ExtractRewardAmount(rewards)
    if type(rewards) ~= "table" then return 0 end
    local directReward = rewards[Player.Name] or rewards[Player.UserId]
    if directReward ~= nil then return tonumber(directReward) or 0 end
    for key, value in pairs(rewards) do
        if tostring(key) == Player.Name or tonumber(key) == Player.UserId then
            return tonumber(value) or 0
        end
    end
    return 0
end

local function IsSeatOccupiedByPlayer(seatPart)
    if not seatPart then return false end
    if not seatPart:IsA("Seat") and not seatPart:IsA("VehicleSeat") then return false end
    return seatPart.Occupant and seatPart.Occupant.Parent == Character
end

local function GetVehicleModel()
    Character = Player.Character
    if not Character then return nil, nil end
    local humanoid = Character:FindFirstChildOfClass("Humanoid")
    local seat = humanoid and humanoid.SeatPart or nil
    local vehiclesFolder = workspace:FindFirstChild("Vehicles")
    if vehiclesFolder then
        local namedVehicle = vehiclesFolder:FindFirstChild(Player.Name .. "'s Car")
        if namedVehicle then
            local namedSeat = namedVehicle:FindFirstChild("VehicleSeat", true)
            if namedSeat and (namedSeat == seat or IsSeatOccupiedByPlayer(namedSeat)) then
                return namedVehicle, namedSeat
            end
        end
        if seat then
            for _, vehicle in ipairs(vehiclesFolder:GetChildren()) do
                local vehicleSeat = vehicle:FindFirstChild("VehicleSeat", true)
                if vehicleSeat and (vehicleSeat == seat or IsSeatOccupiedByPlayer(vehicleSeat)) then
                    return vehicle, vehicleSeat
                end
            end
        end
    end
    if not seat then return nil, nil end
    local current = seat.Parent
    while current and current ~= workspace do
        if current:FindFirstChild("vehicleType") then return current, seat end
        current = current.Parent
    end
    return seat.Parent, seat
end

local function ZeroVehicleMotion(target)
    if not target then return end
    if target:IsA("Model") then
        for _, part in target:GetDescendants() do
            if part:IsA("BasePart") then
                part.AssemblyLinearVelocity = Vector3.zero
                part.AssemblyAngularVelocity = Vector3.zero
            end
        end
        return
    end
    if target:IsA("BasePart") then
        target.AssemblyLinearVelocity = Vector3.zero
        target.AssemblyAngularVelocity = Vector3.zero
    end
end

local function GetVehiclePivotPart(vehicleModel, seat)
    if vehicleModel then
        local primaryPart = vehicleModel.PrimaryPart
            or vehicleModel:FindFirstChild("VehicleSeat", true)
            or vehicleModel:FindFirstChild("DriveSeat", true)
            or vehicleModel:FindFirstChildWhichIsA("BasePart", true)
        if primaryPart and primaryPart:IsA("BasePart") then
            if vehicleModel.PrimaryPart ~= primaryPart then
                pcall(function() vehicleModel.PrimaryPart = primaryPart end)
            end
            return primaryPart
        end
    end
    return seat
end

local function TeleportVehicleTo(targetCFrame)
    local vehicleModel, seat = GetVehicleModel()
    if not seat then return false end
    local pivotPart = GetVehiclePivotPart(vehicleModel, seat)
    local targetPosition = targetCFrame.Position + Vector3.new(0, CONFIG.TeleportHeightOffset, 0)
    if vehicleModel and vehicleModel:GetAttribute("RootWheelOffset") then
        targetPosition = targetPosition + Vector3.new(0, vehicleModel:GetAttribute("RootWheelOffset"), 0)
    end
    local pivotTarget = targetCFrame.Rotation + targetPosition
    local holderRoot = vehicleModel and (vehicleModel:FindFirstChild("Weight") or vehicleModel:FindFirstChild("Engine")) or nil
    local stopPlaneThrottle = Events:FindFirstChild("StopPlaneThrottle")
    if stopPlaneThrottle and stopPlaneThrottle:IsA("BindableEvent") then
        pcall(function() stopPlaneThrottle:Fire() end)
    end
    ZeroVehicleMotion(vehicleModel or pivotPart)
    if vehicleModel and vehicleModel.PrimaryPart then
        vehicleModel:PivotTo(pivotTarget)
    elseif pivotPart then
        pivotPart.CFrame = pivotTarget
    end
    if holderRoot then
        local posHolder = holderRoot:FindFirstChild("PosHolder")
        local rotHolder = holderRoot:FindFirstChild("RotHolder")
        if posHolder then posHolder.Position = targetPosition end
        if rotHolder then rotHolder.CFrame = targetCFrame.Rotation end
    end
    for _ = 1, 8 do
        RunService.Heartbeat:Wait()
        ZeroVehicleMotion(vehicleModel or pivotPart)
        if vehicleModel and vehicleModel.PrimaryPart then
            vehicleModel:PivotTo(pivotTarget)
        elseif pivotPart then
            pivotPart.CFrame = pivotTarget
        end
    end
    return true
end

local function TweenVehicleTo(targetCFrame)
    local vehicleModel, seat = GetVehicleModel()
    if not seat then return false end
    local pivotPart = GetVehiclePivotPart(vehicleModel, seat)
    local targetPosition = targetCFrame.Position + Vector3.new(0, CONFIG.TeleportHeightOffset, 0)
    if vehicleModel and vehicleModel:GetAttribute("RootWheelOffset") then
        targetPosition = targetPosition + Vector3.new(0, vehicleModel:GetAttribute("RootWheelOffset"), 0)
    end
    local finalCFrame = targetCFrame.Rotation + targetPosition
    local startCFrame
    if vehicleModel and vehicleModel.PrimaryPart then
        startCFrame = vehicleModel:GetPivot()
    elseif pivotPart then
        startCFrame = pivotPart.CFrame
    else
        return false
    end
    local distance = (finalCFrame.Position - startCFrame.Position).Magnitude
    local duration = distance / CONFIG.TweenSpeed
    if duration < 0.05 then
        return TeleportVehicleTo(targetCFrame)
    end
    local stopPlaneThrottle = Events:FindFirstChild("StopPlaneThrottle")
    if stopPlaneThrottle and stopPlaneThrottle:IsA("BindableEvent") then
        pcall(function() stopPlaneThrottle:Fire() end)
    end
    local holderRoot = vehicleModel and (vehicleModel:FindFirstChild("Weight") or vehicleModel:FindFirstChild("Engine")) or nil
    local elapsed = 0
    while elapsed < duration do
        if not State.Running then return false end
        local dt = RunService.Heartbeat:Wait()
        elapsed = elapsed + dt
        local alpha = math.clamp(elapsed / duration, 0, 1)
        local currentCFrame = startCFrame:Lerp(finalCFrame, alpha)
        ZeroVehicleMotion(vehicleModel or pivotPart)
        if vehicleModel and vehicleModel.PrimaryPart then
            vehicleModel:PivotTo(currentCFrame)
        elseif pivotPart then
            pivotPart.CFrame = currentCFrame
        end
        if holderRoot then
            local posHolder = holderRoot:FindFirstChild("PosHolder")
            local rotHolder = holderRoot:FindFirstChild("RotHolder")
            if posHolder then posHolder.Position = currentCFrame.Position end
            if rotHolder then rotHolder.CFrame = currentCFrame.Rotation end
        end
    end
    ZeroVehicleMotion(vehicleModel or pivotPart)
    if vehicleModel and vehicleModel.PrimaryPart then
        vehicleModel:PivotTo(finalCFrame)
    elseif pivotPart then
        pivotPart.CFrame = finalCFrame
    end
    return true
end

local function GetCheckpointCFrame(checkpoint)
    if checkpoint:IsA("BasePart") then return checkpoint.CFrame end
    if checkpoint:IsA("Model") and checkpoint.PrimaryPart then return checkpoint.PrimaryPart.CFrame end
    local part = checkpoint:FindFirstChildWhichIsA("BasePart", true)
    if part then return part.CFrame end
    return nil
end

RaceLoadStart.OnClientEvent:Connect(function()
    RaceState.Queueing = true
    RaceState.Started = false
    RaceState.ActiveRaceName = nil
    RaceState.StartServerTime = 0
    RaceState.RewardAmount = 0
end)

RaceStart.OnClientEvent:Connect(function(raceName, _, startServerTime)
    RaceState.Session = RaceState.Session + 1
    RaceState.Queueing = false
    RaceState.Started = true
    RaceState.ActiveRaceName = raceName
    RaceState.StartServerTime = startServerTime or 0
    RaceState.StartedSession = RaceState.Session
    RaceState.RewardAmount = 0
end)

RaceFinished.OnClientEvent:Connect(function(raceName, _, _, rewards)
    RaceState.Started = false
    RaceState.ActiveRaceName = raceName or RaceState.ActiveRaceName
    RaceState.RewardAmount = ExtractRewardAmount(rewards)
    RaceState.FinishedSession = RaceState.Session
end)

RaceLeft.OnClientEvent:Connect(function()
    RaceState.Started = false
    RaceState.CancelledSession = RaceState.Session
end)

local function GetSortedCheckpoints()
    local raceProps = workspace:FindFirstChild("RaceProps")
    if not raceProps then
        for i = 1, 10 do
            task.wait(0.5)
            raceProps = workspace:FindFirstChild("RaceProps")
            if raceProps then break end
        end
    end
    if not raceProps then return nil end
    local cpFolder = raceProps:FindFirstChild("Checkpoints") or raceProps
    local checkpoints = {}
    for _, child in cpFolder:GetChildren() do
        local num = tonumber(child.Name)
        if num then
            table.insert(checkpoints, { Index = num, Object = child })
        end
    end
    if #checkpoints == 0 then
        for _, container in raceProps:GetDescendants() do
            local num = tonumber(container.Name)
            if num and (container:IsA("Model") or container:IsA("BasePart") or container:IsA("Folder")) then
                if container:FindFirstChildWhichIsA("BasePart", true) or container:IsA("BasePart") then
                    local exists = false
                    for _, cp in checkpoints do
                        if cp.Index == num then exists = true break end
                    end
                    if not exists then
                        table.insert(checkpoints, { Index = num, Object = container })
                    end
                end
            end
        end
    end
    table.sort(checkpoints, function(a, b) return a.Index < b.Index end)
    return checkpoints
end

local function TeleportToRaceStart(raceName)
    local teleportValue = RaceTeleports:FindFirstChild(raceName)
    if teleportValue then
        return TeleportVehicleTo(teleportValue.Value)
    end
    local racesFolder = workspace:FindFirstChild("Races")
    if racesFolder then
        local raceObj = racesFolder:FindFirstChild(raceName)
        if raceObj then
            local startPart = raceObj:FindFirstChild("Start")
                or raceObj:FindFirstChild("StartZone")
                or raceObj:FindFirstChild("Detector")
                or raceObj:FindFirstChildWhichIsA("BasePart", true)
            if startPart then
                local cf
                if startPart:IsA("BasePart") then
                    cf = startPart.CFrame
                elseif startPart:IsA("Model") and startPart.PrimaryPart then
                    cf = startPart.PrimaryPart.CFrame
                end
                if cf then return TeleportVehicleTo(cf) end
            end
        end
    end
    local raceData = RaceStorage:FindFirstChild(raceName)
    if raceData then
        local cpFolder = raceData:FindFirstChild("Checkpoints")
        if cpFolder then
            local firstCp = cpFolder:FindFirstChild("1")
            if firstCp then
                local cf = GetCheckpointCFrame(firstCp)
                if cf then return TeleportVehicleTo(cf + Vector3.new(0, 0, -30)) end
            end
        end
    end
    return false
end

local StatusLabel, ProgressLabel, CompletedLabel, EarnedLabel, TimeLabel, CreditsLabel
local FarmToggle

local function RunCheckpointsThroughRace(raceName, raceSession)
    local totalLaps = RaceLaps[raceName] or 1
    task.wait(2)
    local checkpoints = GetSortedCheckpoints()
    if not checkpoints or #checkpoints == 0 then
        task.wait(2)
        checkpoints = GetSortedCheckpoints()
    end
    if not checkpoints or #checkpoints == 0 then return false end
    local totalCheckpoints = #checkpoints
    for lap = 1, totalLaps do
        for i, cp in ipairs(checkpoints) do
            if not State.Running then return false, "stopped" end
            if RaceState.CancelledSession == raceSession then return false, "cancelled" end
            if RaceState.FinishedSession == raceSession then return true, "finished" end
            if ProgressLabel then
                ProgressLabel:Set(string.format("Lap %d/%d | CP %d/%d", lap, totalLaps, i, totalCheckpoints))
            end
            local cpCFrame = GetCheckpointCFrame(cp.Object)
            if cpCFrame then
                if not TweenVehicleTo(cpCFrame) then return false, "teleport-failed" end
                pcall(function() CheckRemote:FireServer(cp.Index, raceName) end)
                if RaceState.FinishedSession == raceSession then return true, "finished" end
                if RaceState.CancelledSession == raceSession then return false, "cancelled" end
                if lap == totalLaps and i == totalCheckpoints then
                    task.wait(0.1)
                else
                    task.wait(CONFIG.CheckpointDelay)
                end
            end
        end
        if lap < totalLaps then
            if ProgressLabel then
                ProgressLabel:Set(string.format("Lap %d done, starting lap %d...", lap, lap + 1))
            end
            task.wait(1)
        end
    end
    return true, "checkpoint-loop-complete"
end

local function WaitForRaceStart(timeout, minimumSession, expectedRaceName)
    local elapsed = 0
    while elapsed < timeout and State.Running do
        if RaceState.Started and RaceState.StartedSession > minimumSession then
            if not expectedRaceName or RaceState.ActiveRaceName == expectedRaceName then
                return true, RaceState.ActiveRaceName, RaceState.StartedSession, RaceState.StartServerTime
            end
        end
        task.wait(0.1)
        elapsed = elapsed + 0.1
    end
    return false, nil, nil, nil
end

local function WaitForRaceCountdown(startServerTime)
    if type(startServerTime) ~= "number" or startServerTime <= 0 then
        task.wait(4)
        return
    end
    while State.Running do
        local remaining = startServerTime - workspace:GetServerTimeNow()
        if remaining <= 0.05 then break end
        if ProgressLabel then
            ProgressLabel:Set(string.format("Countdown %.1fs", math.max(remaining, 0)))
        end
        task.wait(math.min(0.2, remaining))
    end
    task.wait(0.1)
end

local function WaitForRaceResolution(raceSession, timeout)
    local elapsed = 0
    while elapsed < timeout and State.Running do
        if RaceState.FinishedSession == raceSession then return "finished", RaceState.RewardAmount end
        if RaceState.CancelledSession == raceSession then return "cancelled", 0 end
        task.wait(0.1)
        elapsed = elapsed + 0.1
    end
    return "timeout", 0
end

local function AutoFarmLoop()
    State.StartTime = tick()
    State.RacesCompleted = 0
    State.TotalEarned = 0

    while State.Running do
        local raceName = CONFIG.SelectedRace
        local estimatedReward = RaceRewards[raceName] or 0
        local queueTimeout = (RaceTimeouts[raceName] or 200) + 30
        local sessionBeforeQueue = RaceState.Session

        Character = Player.Character
        if not Character then
            if StatusLabel then StatusLabel:Set("Waiting for character...") end
            Character = Player.CharacterAdded:Wait()
            task.wait(2)
        end

        local vehicleModel, seat = GetVehicleModel()
        if not seat then
            if StatusLabel then StatusLabel:Set("Get in a vehicle!") end
            while State.Running do
                task.wait(1)
                vehicleModel, seat = GetVehicleModel()
                if seat then break end
            end
            if not State.Running then break end
            task.wait(1)
        end

        if StatusLabel then StatusLabel:Set("Going to race...") end
        if ProgressLabel then ProgressLabel:Set("Teleporting...") end

        if not TeleportToRaceStart(raceName) then
            if StatusLabel then StatusLabel:Set("Teleport failed") end
            task.wait(3)
            continue
        end

        task.wait(3)

        if StatusLabel then StatusLabel:Set("In queue (waiting " .. (RaceTimeouts[raceName] or "???") .. "s)...") end
        if ProgressLabel then ProgressLabel:Set("Waiting for race...") end

        local started, startedRaceName, raceSession, startServerTime = WaitForRaceStart(queueTimeout, sessionBeforeQueue, raceName)
        if not started then
            if not State.Running then break end
            if StatusLabel then StatusLabel:Set("Race didn't start, retrying...") end
            pcall(function() LeaveRace:FireServer() end)
            task.wait(CONFIG.LoopDelay)
            continue
        end

        local activeRaceName = startedRaceName or raceName
        State.CurrentRaceName = activeRaceName

        if StatusLabel then StatusLabel:Set("Countdown...") end
        WaitForRaceCountdown(startServerTime)

        if StatusLabel then StatusLabel:Set("Racing!") end
        State.InRace = true

        local raceSuccess, raceResult = RunCheckpointsThroughRace(activeRaceName, raceSession)

        if raceSuccess and State.Running then
            if StatusLabel then StatusLabel:Set("Finishing...") end
            local resolution, reward = WaitForRaceResolution(raceSession, 30)
            State.InRace = false

            if resolution == "finished" then
                State.RacesCompleted = State.RacesCompleted + 1
                local earned = reward > 0 and reward or estimatedReward
                State.TotalEarned = State.TotalEarned + earned
                if CompletedLabel then CompletedLabel:Set("Races Done: " .. State.RacesCompleted) end
                if EarnedLabel then EarnedLabel:Set("Estimated Earned: $" .. AddCommas(State.TotalEarned)) end
                if StatusLabel then StatusLabel:Set("+$" .. AddCommas(earned) .. " earned!") end
            elseif resolution == "cancelled" then
                if StatusLabel then StatusLabel:Set("Race cancelled") end
            else
                if StatusLabel then StatusLabel:Set("Race timed out") end
                pcall(function() LeaveRace:FireServer() end)
            end
        else
            State.InRace = false
            if not State.Running then break end
            if raceResult == "cancelled" then
                if StatusLabel then StatusLabel:Set("Race cancelled") end
            else
                if StatusLabel then StatusLabel:Set("Race failed, retrying...") end
            end
            pcall(function() LeaveRace:FireServer() end)
        end

        State.CurrentRaceName = nil

        if CONFIG.ClaimOfflineRewards then
            pcall(function() ClaimDrivingOffline:FireServer() end)
        end

        pcall(function()
            if _G.newDataSystem and _G.newDataSystem.Economy then
                if CreditsLabel then CreditsLabel:Set("Balance: $" .. AddCommas(_G.newDataSystem.Economy.Credits.Value)) end
            end
        end)

        if ProgressLabel then ProgressLabel:Set("Next race in " .. CONFIG.LoopDelay .. "s...") end
        task.wait(CONFIG.LoopDelay)
    end

    if StatusLabel then StatusLabel:Set("Stopped") end
    if ProgressLabel then ProgressLabel:Set("--") end
end

local Window = Rayfield:CreateWindow({
    Name = "Crocky Hub",
    LoadingTitle = "Crocky Hub",
    LoadingSubtitle = "Vehicle Legends",
    Theme = "Default",
    ToggleUIKeybind = "K",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = true,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "CrockyHub",
        FileName = "VehicleLegends"
    },
    Discord = {
        Enabled = true,
        Invite = "Yan2XC8HTx",
        RememberJoins = true
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Auto Farm", "zap")
local SettingsTab = Window:CreateTab("Settings", "settings")

MainTab:CreateSection("Status")
StatusLabel = MainTab:CreateLabel("Stopped")
ProgressLabel = MainTab:CreateLabel("--")
CompletedLabel = MainTab:CreateLabel("Races Done: 0")
EarnedLabel = MainTab:CreateLabel("Estimated Earned: $0")
TimeLabel = MainTab:CreateLabel("Uptime: 0:00:00")
CreditsLabel = MainTab:CreateLabel("Balance: Loading...")

MainTab:CreateSection("Controls")

FarmToggle = MainTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Callback = function(Value)
        if Value == State.Running then return end
        State.Running = Value
        if Value then
            if StatusLabel then StatusLabel:Set("Starting...") end
            task.spawn(AutoFarmLoop)
        else
            State.InRace = false
            pcall(function() LeaveRace:FireServer() end)
        end
    end,
})

MainTab:CreateDropdown({
    Name = "Race Selection",
    Options = RaceOptions,
    CurrentOption = {CONFIG.SelectedRace},
    MultipleOptions = false,
    Flag = "RaceSelection",
    Callback = function(Options)
        CONFIG.SelectedRace = Options[1]
    end,
})

MainTab:CreateKeybind({
    Name = "Toggle Keybind",
    CurrentKeybind = "F6",
    HoldToInteract = false,
    Flag = "ToggleKeybind",
    Callback = function()
        FarmToggle:Set(not State.Running)
    end,
})

SettingsTab:CreateSection("Timing")

SettingsTab:CreateSlider({
    Name = "Checkpoint Delay",
    Range = {0, 3},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = 0.1,
    Flag = "CheckpointDelay",
    Callback = function(Value)
        CONFIG.CheckpointDelay = Value
    end,
})

SettingsTab:CreateSlider({
    Name = "Loop Delay",
    Range = {1, 15},
    Increment = 1,
    Suffix = "s",
    CurrentValue = 5,
    Flag = "LoopDelay",
    Callback = function(Value)
        CONFIG.LoopDelay = Value
    end,
})

SettingsTab:CreateSection("Movement")

SettingsTab:CreateSlider({
    Name = "Tween Speed",
    Range = {100, 800},
    Increment = 25,
    Suffix = " studs/s",
    CurrentValue = 300,
    Flag = "TweenSpeed",
    Callback = function(Value)
        CONFIG.TweenSpeed = Value
    end,
})

SettingsTab:CreateSlider({
    Name = "Height Offset",
    Range = {0, 20},
    Increment = 1,
    Suffix = "",
    CurrentValue = 0,
    Flag = "HeightOffset",
    Callback = function(Value)
        CONFIG.TeleportHeightOffset = Value
    end,
})

SettingsTab:CreateSection("Other")

SettingsTab:CreateToggle({
    Name = "Claim Offline Rewards",
    CurrentValue = true,
    Flag = "ClaimOffline",
    Callback = function(Value)
        CONFIG.ClaimOfflineRewards = Value
    end,
})

SettingsTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(Value)
        CONFIG.AntiAFK = Value
    end,
})

SettingsTab:CreateParagraph({
    Title = "Info",
    Content = "Changes apply live. Race changes take effect on next loop. Press K to toggle UI. discord.gg/Yan2XC8HTx"
})

local VirtualUser = game:GetService("VirtualUser")
Player.Idled:Connect(function()
    if not CONFIG.AntiAFK then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

task.spawn(function()
    while true do
        if State.Running and State.StartTime > 0 then
            if TimeLabel then TimeLabel:Set("Uptime: " .. FormatTime(tick() - State.StartTime)) end
        end
        pcall(function()
            if _G.newDataSystem and _G.newDataSystem.Economy then
                if CreditsLabel then CreditsLabel:Set("Balance: $" .. AddCommas(_G.newDataSystem.Economy.Credits.Value)) end
            end
        end)
        task.wait(1)
    end
end)

Player.CharacterAdded:Connect(function(char)
    Character = char
    State.InRace = false
end)

Rayfield:LoadConfiguration()
