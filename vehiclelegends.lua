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

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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

    CheckpointDelay = 1.5,

    LoopDelay = 5,

    ClaimOfflineRewards = true,

    ToggleKey = Enum.KeyCode.F6,

    AntiAFK = true,

    TeleportHeightOffset = 0,
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

local function CreateGui()
    local existing = Player.PlayerGui:FindFirstChild("AutoFarmGui")
    if existing then existing:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoFarmGui"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = Player.PlayerGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 360, 0, 560)
    MainFrame.Position = UDim2.new(0, 12, 0.5, -280)
    MainFrame.BackgroundColor3 = Color3.fromRGB(17, 20, 28)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 14)
    MainCorner.Parent = MainFrame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(74, 145, 255)
    Stroke.Thickness = 2
    Stroke.Parent = MainFrame

    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 42)
    TitleBar.BackgroundColor3 = Color3.fromRGB(27, 34, 48)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 14)
    TitleCorner.Parent = TitleBar

    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -80, 1, 0)
    Title.Position = UDim2.new(0, 14, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Crocky Hub [discord.gg/Yan2XC8HTx]"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.TextScaled = true
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    local MinBtn = Instance.new("TextButton")
    MinBtn.Name = "MinBtn"
    MinBtn.Size = UDim2.new(0, 26, 0, 26)
    MinBtn.Position = UDim2.new(1, -34, 0, 8)
    MinBtn.BackgroundColor3 = Color3.fromRGB(35, 44, 61)
    MinBtn.BorderSizePixel = 0
    MinBtn.Text = "-"
    MinBtn.TextColor3 = Color3.fromRGB(220, 228, 240)
    MinBtn.TextSize = 18
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.Parent = TitleBar

    local MinBtnCorner = Instance.new("UICorner")
    MinBtnCorner.CornerRadius = UDim.new(1, 0)
    MinBtnCorner.Parent = MinBtn

    local StatsFrame = Instance.new("Frame")
    StatsFrame.Name = "StatsFrame"
    StatsFrame.Size = UDim2.new(1, -20, 0, 194)
    StatsFrame.Position = UDim2.new(0, 10, 0, 52)
    StatsFrame.BackgroundColor3 = Color3.fromRGB(24, 29, 40)
    StatsFrame.BorderSizePixel = 0
    StatsFrame.Parent = MainFrame

    local StatsCorner = Instance.new("UICorner")
    StatsCorner.CornerRadius = UDim.new(0, 12)
    StatsCorner.Parent = StatsFrame

    local StatsStroke = Instance.new("UIStroke")
    StatsStroke.Color = Color3.fromRGB(45, 58, 80)
    StatsStroke.Thickness = 1
    StatsStroke.Parent = StatsFrame

    local StatsTitle = Instance.new("TextLabel")
    StatsTitle.Size = UDim2.new(1, -20, 0, 22)
    StatsTitle.Position = UDim2.new(0, 10, 0, 6)
    StatsTitle.BackgroundTransparency = 1
    StatsTitle.Text = "LIVE STATUS"
    StatsTitle.TextColor3 = Color3.fromRGB(116, 153, 216)
    StatsTitle.TextSize = 12
    StatsTitle.Font = Enum.Font.GothamBold
    StatsTitle.TextXAlignment = Enum.TextXAlignment.Left
    StatsTitle.Parent = StatsFrame

    local function MakeLabel(parent, name, text, yPos, color)
        local label = Instance.new("TextLabel")
        label.Name = name
        label.Size = UDim2.new(1, -20, 0, 18)
        label.Position = UDim2.new(0, 10, 0, yPos)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = color or Color3.fromRGB(206, 214, 230)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.Parent = parent
        return label
    end

    local StatusLabel = MakeLabel(StatsFrame, "Status", "Status: STOPPED", 30, Color3.fromRGB(255, 120, 120))
    local RaceLabel = MakeLabel(StatsFrame, "Race", "Selected: " .. CONFIG.SelectedRace, 50)
    local SettingsLabel = MakeLabel(StatsFrame, "Settings", "Delay 1.5s | Loop 5s | Height 0", 70)
    local ProgressLabel = MakeLabel(StatsFrame, "Progress", "Progress: --", 90)
    local CompletedLabel = MakeLabel(StatsFrame, "Completed", "Races Done: 0", 110)
    local EarnedLabel = MakeLabel(StatsFrame, "Earned", "Estimated Earned: $0", 130)
    local TimeLabel = MakeLabel(StatsFrame, "Time", "Uptime: 0:00:00", 150)
    local CreditsLabel = MakeLabel(StatsFrame, "Credits", "Balance: Loading...", 170)

    local ControlsTitle = Instance.new("TextLabel")
    ControlsTitle.Name = "ControlsTitle"
    ControlsTitle.Size = UDim2.new(1, -20, 0, 22)
    ControlsTitle.Position = UDim2.new(0, 10, 0, 256)
    ControlsTitle.BackgroundTransparency = 1
    ControlsTitle.Text = "SETTINGS"
    ControlsTitle.TextColor3 = Color3.fromRGB(116, 153, 216)
    ControlsTitle.TextSize = 12
    ControlsTitle.Font = Enum.Font.GothamBold
    ControlsTitle.TextXAlignment = Enum.TextXAlignment.Left
    ControlsTitle.Parent = MainFrame

    local ControlsFrame = Instance.new("ScrollingFrame")
    ControlsFrame.Name = "ControlsFrame"
    ControlsFrame.Size = UDim2.new(1, -20, 0, 220)
    ControlsFrame.Position = UDim2.new(0, 10, 0, 282)
    ControlsFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    ControlsFrame.BorderSizePixel = 0
    ControlsFrame.ScrollBarThickness = 4
    ControlsFrame.ScrollBarImageColor3 = Color3.fromRGB(78, 124, 201)
    ControlsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ControlsFrame.Parent = MainFrame

    local ControlsCorner = Instance.new("UICorner")
    ControlsCorner.CornerRadius = UDim.new(0, 12)
    ControlsCorner.Parent = ControlsFrame

    local ControlsStroke = Instance.new("UIStroke")
    ControlsStroke.Color = Color3.fromRGB(45, 58, 80)
    ControlsStroke.Thickness = 1
    ControlsStroke.Parent = ControlsFrame

    local ControlsPadding = Instance.new("UIPadding")
    ControlsPadding.PaddingLeft = UDim.new(0, 10)
    ControlsPadding.PaddingRight = UDim.new(0, 10)
    ControlsPadding.PaddingTop = UDim.new(0, 10)
    ControlsPadding.PaddingBottom = UDim.new(0, 10)
    ControlsPadding.Parent = ControlsFrame

    local ControlsList = Instance.new("UIListLayout")
    ControlsList.Padding = UDim.new(0, 8)
    ControlsList.SortOrder = Enum.SortOrder.LayoutOrder
    ControlsList.Parent = ControlsFrame

    local function UpdateCanvas()
        ControlsFrame.CanvasSize = UDim2.new(0, 0, 0, ControlsList.AbsoluteContentSize.Y + 20)
    end
    ControlsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCanvas)

    local function CreateControlCard(height)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, height)
        card.BackgroundColor3 = Color3.fromRGB(29, 35, 49)
        card.BorderSizePixel = 0
        card.Parent = ControlsFrame

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent = card

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = Color3.fromRGB(53, 67, 91)
        cardStroke.Thickness = 1
        cardStroke.Parent = card

        return card
    end

    local function CreateControlTitle(parent, text, yPos)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 18)
        label.Position = UDim2.new(0, 10, 0, yPos)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(232, 236, 242)
        label.TextSize = 13
        label.Font = Enum.Font.GothamMedium
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = parent
        return label
    end

    local function CreateDropdown(titleText, options, getter, setter)
        local row = CreateControlCard(72)
        row.ClipsDescendants = true
        CreateControlTitle(row, titleText, 8)

        local selectButton = Instance.new("TextButton")
        selectButton.Size = UDim2.new(1, -20, 0, 30)
        selectButton.Position = UDim2.new(0, 10, 0, 32)
        selectButton.BackgroundColor3 = Color3.fromRGB(21, 26, 37)
        selectButton.BorderSizePixel = 0
        selectButton.TextColor3 = Color3.fromRGB(240, 243, 247)
        selectButton.TextSize = 13
        selectButton.Font = Enum.Font.Gotham
        selectButton.TextXAlignment = Enum.TextXAlignment.Left
        selectButton.Parent = row

        local selectCorner = Instance.new("UICorner")
        selectCorner.CornerRadius = UDim.new(0, 8)
        selectCorner.Parent = selectButton

        local buttonPadding = Instance.new("UIPadding")
        buttonPadding.PaddingLeft = UDim.new(0, 10)
        buttonPadding.PaddingRight = UDim.new(0, 22)
        buttonPadding.Parent = selectButton

        local arrow = Instance.new("TextLabel")
        arrow.Size = UDim2.new(0, 18, 1, 0)
        arrow.Position = UDim2.new(1, -20, 0, 0)
        arrow.BackgroundTransparency = 1
        arrow.Text = "v"
        arrow.TextColor3 = Color3.fromRGB(158, 173, 198)
        arrow.TextSize = 14
        arrow.Font = Enum.Font.GothamBold
        arrow.Parent = selectButton

        local listHolder = Instance.new("Frame")
        listHolder.Size = UDim2.new(1, -20, 0, 170)
        listHolder.Position = UDim2.new(0, 10, 0, 68)
        listHolder.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
        listHolder.BorderSizePixel = 0
        listHolder.Visible = false
        listHolder.Parent = row

        local listCorner = Instance.new("UICorner")
        listCorner.CornerRadius = UDim.new(0, 8)
        listCorner.Parent = listHolder

        local optionsScroll = Instance.new("ScrollingFrame")
        optionsScroll.Size = UDim2.new(1, 0, 1, 0)
        optionsScroll.BackgroundTransparency = 1
        optionsScroll.BorderSizePixel = 0
        optionsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        optionsScroll.ScrollBarThickness = 4
        optionsScroll.ScrollBarImageColor3 = Color3.fromRGB(78, 124, 201)
        optionsScroll.Parent = listHolder

        local optionsLayout = Instance.new("UIListLayout")
        optionsLayout.Padding = UDim.new(0, 4)
        optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        optionsLayout.Parent = optionsScroll

        local optionsPadding = Instance.new("UIPadding")
        optionsPadding.PaddingLeft = UDim.new(0, 6)
        optionsPadding.PaddingRight = UDim.new(0, 6)
        optionsPadding.PaddingTop = UDim.new(0, 6)
        optionsPadding.PaddingBottom = UDim.new(0, 6)
        optionsPadding.Parent = optionsScroll

        optionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            optionsScroll.CanvasSize = UDim2.new(0, 0, 0, optionsLayout.AbsoluteContentSize.Y + 12)
        end)

        local open = false
        local maxVisibleRows = math.min(#options, 6)
        local expandedHeight = 72 + 10 + maxVisibleRows * 28

        local function RefreshDropdownButton()
            selectButton.Text = getter()
        end

        local function SetOpen(state)
            open = state
            listHolder.Visible = open
            row.Size = UDim2.new(1, 0, 0, open and expandedHeight or 72)
            arrow.Text = open and "^" or "v"
            UpdateCanvas()
        end

        selectButton.MouseButton1Click:Connect(function()
            SetOpen(not open)
        end)

        for _, option in ipairs(options) do
            local optionButton = Instance.new("TextButton")
            optionButton.Size = UDim2.new(1, 0, 0, 24)
            optionButton.BackgroundColor3 = Color3.fromRGB(31, 39, 54)
            optionButton.BorderSizePixel = 0
            optionButton.Text = option
            optionButton.TextColor3 = Color3.fromRGB(234, 238, 245)
            optionButton.TextSize = 12
            optionButton.Font = Enum.Font.Gotham
            optionButton.Parent = optionsScroll

            local optionCorner = Instance.new("UICorner")
            optionCorner.CornerRadius = UDim.new(0, 6)
            optionCorner.Parent = optionButton

            optionButton.MouseButton1Click:Connect(function()
                setter(option)
                RefreshDropdownButton()
                RaceLabel.Text = "Selected: " .. CONFIG.SelectedRace
                SetOpen(false)
            end)
        end

        RefreshDropdownButton()
        return row
    end

    local function CreateSlider(titleText, minValue, maxValue, step, getter, setter, suffix)
        local row = CreateControlCard(72)
        CreateControlTitle(row, titleText, 8)

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0, 80, 0, 18)
        valueLabel.Position = UDim2.new(1, -90, 0, 8)
        valueLabel.BackgroundTransparency = 1
        valueLabel.TextColor3 = Color3.fromRGB(145, 220, 173)
        valueLabel.TextSize = 12
        valueLabel.Font = Enum.Font.GothamMedium
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = row

        local track = Instance.new("Frame")
        track.Size = UDim2.new(1, -24, 0, 8)
        track.Position = UDim2.new(0, 12, 0, 44)
        track.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
        track.BorderSizePixel = 0
        track.Parent = row

        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(74, 145, 255)
        fill.BorderSizePixel = 0
        fill.Parent = track

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill

        local knob = Instance.new("TextButton")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.BackgroundColor3 = Color3.fromRGB(240, 244, 250)
        knob.BorderSizePixel = 0
        knob.Text = ""
        knob.AutoButtonColor = false
        knob.Parent = track

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local draggingSlider = false

        local function SnapValue(rawValue)
            local snapped = minValue + math.floor(((rawValue - minValue) / step) + 0.5) * step
            snapped = math.clamp(snapped, minValue, maxValue)
            if step < 1 then
                snapped = tonumber(string.format("%.1f", snapped))
            else
                snapped = math.floor(snapped + 0.5)
            end
            return snapped
        end

        local function UpdateVisual()
            local currentValue = getter()
            local alpha = (currentValue - minValue) / (maxValue - minValue)
            fill.Size = UDim2.new(alpha, 0, 1, 0)
            knob.Position = UDim2.new(alpha, 0, 0.5, 0)
            if step < 1 then
                valueLabel.Text = string.format("%.1f%s", currentValue, suffix or "")
            else
                valueLabel.Text = string.format("%d%s", currentValue, suffix or "")
            end
        end

        local function UpdateFromInput(input)
            local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local value = SnapValue(minValue + (maxValue - minValue) * alpha)
            setter(value)
            UpdateVisual()
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSlider = true
                UpdateFromInput(input)
            end
        end)

        knob.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSlider = true
                UpdateFromInput(input)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                UpdateFromInput(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSlider = false
            end
        end)

        UpdateVisual()
        return row
    end

    local function CreateToggle(titleText, getter, setter)
        local row = CreateControlCard(58)
        CreateControlTitle(row, titleText, 10)

        local pill = Instance.new("TextButton")
        pill.Size = UDim2.new(0, 52, 0, 28)
        pill.Position = UDim2.new(1, -64, 0, 15)
        pill.BorderSizePixel = 0
        pill.Text = ""
        pill.AutoButtonColor = false
        pill.Parent = row

        local pillCorner = Instance.new("UICorner")
        pillCorner.CornerRadius = UDim.new(1, 0)
        pillCorner.Parent = pill

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 22, 0, 22)
        knob.Position = UDim2.new(0, 3, 0.5, -11)
        knob.BackgroundColor3 = Color3.fromRGB(245, 247, 250)
        knob.BorderSizePixel = 0
        knob.Parent = pill

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local function UpdateToggle()
            local enabled = getter()
            local pillColor = enabled and Color3.fromRGB(70, 180, 108) or Color3.fromRGB(75, 84, 102)
            local knobPosition = enabled and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
            TweenService:Create(pill, TweenInfo.new(0.12), { BackgroundColor3 = pillColor }):Play()
            TweenService:Create(knob, TweenInfo.new(0.12), { Position = knobPosition }):Play()
        end

        pill.MouseButton1Click:Connect(function()
            setter(not getter())
            UpdateToggle()
        end)

        UpdateToggle()
        return row
    end

    CreateDropdown("Race Selection", RaceOptions, function()
        return CONFIG.SelectedRace
    end, function(value)
        CONFIG.SelectedRace = value
    end)

    CreateSlider("Checkpoint Delay", 1.0, 3.0, 0.1, function()
        return CONFIG.CheckpointDelay
    end, function(value)
        CONFIG.CheckpointDelay = value
    end, "s")

    CreateSlider("Loop Delay", 1, 15, 1, function()
        return CONFIG.LoopDelay
    end, function(value)
        CONFIG.LoopDelay = value
    end, "s")

    CreateSlider("Teleport Height Offset", 0, 20, 1, function()
        return CONFIG.TeleportHeightOffset
    end, function(value)
        CONFIG.TeleportHeightOffset = value
    end, "")

    CreateToggle("Claim Offline Rewards", function()
        return CONFIG.ClaimOfflineRewards
    end, function(value)
        CONFIG.ClaimOfflineRewards = value
    end)

    CreateToggle("Anti AFK", function()
        return CONFIG.AntiAFK
    end, function(value)
        CONFIG.AntiAFK = value
    end)

    local NoteCard = CreateControlCard(52)
    local Note = Instance.new("TextLabel")
    Note.Size = UDim2.new(1, -20, 1, -12)
    Note.Position = UDim2.new(0, 10, 0, 6)
    Note.BackgroundTransparency = 1
    Note.Text = "Changes apply live. Race changes are picked up on the next race loop. Make sure to join the discord to keep up with updates and get more scripts discord.gg/Yan2XC8HTx"
    Note.TextColor3 = Color3.fromRGB(176, 188, 208)
    Note.TextSize = 11
    Note.Font = Enum.Font.Gotham
    Note.TextWrapped = true
    Note.TextXAlignment = Enum.TextXAlignment.Left
    Note.TextYAlignment = Enum.TextYAlignment.Top
    Note.Parent = NoteCard

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Name = "ToggleBtn"
    ToggleBtn.Size = UDim2.new(1, -20, 0, 40)
    ToggleBtn.Position = UDim2.new(0, 10, 1, -50)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
    ToggleBtn.BorderSizePixel = 0
    ToggleBtn.Text = "START (F6)"
    ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleBtn.TextSize = 16
    ToggleBtn.Font = Enum.Font.GothamBold
    ToggleBtn.Parent = MainFrame

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 10)
    ToggleCorner.Parent = ToggleBtn

    UpdateCanvas()

    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)

    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    local minimized = false
    local expandedSize = UDim2.new(0, 360, 0, 560)
    local collapsedSize = UDim2.new(0, 360, 0, 42)
    local collapsible = { StatsFrame, ControlsTitle, ControlsFrame, ToggleBtn }

    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        for _, item in ipairs(collapsible) do
            item.Visible = not minimized
        end
        MainFrame.Size = minimized and collapsedSize or expandedSize
        MinBtn.Text = minimized and "+" or "-"
    end)

    return {
        Gui = ScreenGui,
        StatusLabel = StatusLabel,
        RaceLabel = RaceLabel,
        SettingsLabel = SettingsLabel,
        ProgressLabel = ProgressLabel,
        CompletedLabel = CompletedLabel,
        EarnedLabel = EarnedLabel,
        TimeLabel = TimeLabel,
        CreditsLabel = CreditsLabel,
        ToggleBtn = ToggleBtn,
    }
end

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
    if type(rewards) ~= "table" then
        return 0
    end

    local directReward = rewards[Player.Name] or rewards[Player.UserId]
    if directReward ~= nil then
        return tonumber(directReward) or 0
    end

    for key, value in pairs(rewards) do
        if tostring(key) == Player.Name or tonumber(key) == Player.UserId then
            return tonumber(value) or 0
        end
    end

    return 0
end

local function IsSeatOccupiedByPlayer(seatPart)
    if not seatPart then
        return false
    end
    if not seatPart:IsA("Seat") and not seatPart:IsA("VehicleSeat") then
        return false
    end
    return seatPart.Occupant and seatPart.Occupant.Parent == Character
end

local function GetVehicleModel()
    Character = Player.Character
    if not Character then
        return nil, nil
    end

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

    if not seat then
        return nil, nil
    end

    local current = seat.Parent
    while current and current ~= workspace do
        if current:FindFirstChild("vehicleType") then
            return current, seat
        end
        current = current.Parent
    end

    return seat.Parent, seat
end

local function ZeroVehicleMotion(target)
    if not target then
        return
    end

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
                pcall(function()
                    vehicleModel.PrimaryPart = primaryPart
                end)
            end
            return primaryPart
        end
    end

    return seat
end

local function TeleportVehicleTo(targetCFrame)
    local vehicleModel, seat = GetVehicleModel()
    if not seat then
        warn("[AutoFarm] No vehicle seat found! Sit in a vehicle first.")
        return false
    end

    local pivotPart = GetVehiclePivotPart(vehicleModel, seat)
    local targetPosition = targetCFrame.Position + Vector3.new(0, CONFIG.TeleportHeightOffset, 0)

    if vehicleModel and vehicleModel:GetAttribute("RootWheelOffset") then
        targetPosition = targetPosition + Vector3.new(0, vehicleModel:GetAttribute("RootWheelOffset"), 0)
    end

    local pivotTarget = targetCFrame.Rotation + targetPosition
    local holderRoot = vehicleModel and (vehicleModel:FindFirstChild("Weight") or vehicleModel:FindFirstChild("Engine")) or nil
    local stopPlaneThrottle = Events:FindFirstChild("StopPlaneThrottle")

    if stopPlaneThrottle and stopPlaneThrottle:IsA("BindableEvent") then
        pcall(function()
            stopPlaneThrottle:Fire()
        end)
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
        if posHolder then
            posHolder.Position = targetPosition
        end
        if rotHolder then
            rotHolder.CFrame = targetCFrame.Rotation
        end
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

local function GetCheckpointCFrame(checkpoint)
    if checkpoint:IsA("BasePart") then
        return checkpoint.CFrame
    end

    if checkpoint:IsA("Model") and checkpoint.PrimaryPart then
        return checkpoint.PrimaryPart.CFrame
    end

    local part = checkpoint:FindFirstChildWhichIsA("BasePart", true)
    if part then
        return part.CFrame
    end

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

    local cpFolder = raceProps:FindFirstChild("Checkpoints")
    if not cpFolder then

        cpFolder = raceProps
    end

    local checkpoints = {}
    for _, child in cpFolder:GetChildren() do
        local num = tonumber(child.Name)
        if num then
            table.insert(checkpoints, { Index = num, Object = child })
        end
    end

    if #checkpoints == 0 then

        for _, container in raceProps:GetDescendants() do
            if container.Parent and container.Parent.Parent == raceProps then

            end
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

    table.sort(checkpoints, function(a, b)
        return a.Index < b.Index
    end)

    return checkpoints
end

local function SetupAntiAFK()
    local VirtualUser = game:GetService("VirtualUser")
    Player.Idled:Connect(function()
        if not CONFIG.AntiAFK then
            return
        end
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local function TeleportToRaceStart(raceName)

    local teleportValue = RaceTeleports:FindFirstChild(raceName)
    if teleportValue then
        local cf = teleportValue.Value
        return TeleportVehicleTo(cf)
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
                if cf then
                    return TeleportVehicleTo(cf)
                end
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
                if cf then
                    return TeleportVehicleTo(cf + Vector3.new(0, 0, -30))
                end
            end
        end
    end

    warn("[AutoFarm] Could not find race start for: " .. raceName)
    return false
end

local function RunCheckpointsThroughRace(raceName, gui, raceSession)
    local totalLaps = RaceLaps[raceName] or 1

    task.wait(2)

    local checkpoints = GetSortedCheckpoints()
    if not checkpoints or #checkpoints == 0 then
        warn("[AutoFarm] No checkpoints found! Looking harder...")
        task.wait(2)
        checkpoints = GetSortedCheckpoints()
    end

    if not checkpoints or #checkpoints == 0 then
        warn("[AutoFarm] Still no checkpoints found for: " .. raceName)
        return false
    end

    local totalCheckpoints = #checkpoints
    print("[AutoFarm] Found " .. totalCheckpoints .. " checkpoints, " .. totalLaps .. " lap(s)")

    for lap = 1, totalLaps do
        for i, cp in ipairs(checkpoints) do
            if not State.Running then return false, "stopped" end
            if RaceState.CancelledSession == raceSession then return false, "cancelled" end
            if RaceState.FinishedSession == raceSession then return true, "finished" end

            if gui then
                gui.ProgressLabel.Text = string.format(
                    "Progress: Lap %d/%d - CP %d/%d",
                    lap, totalLaps, i, totalCheckpoints
                )
            end

            local cpCFrame = GetCheckpointCFrame(cp.Object)
            if cpCFrame then
                local success = TeleportVehicleTo(cpCFrame)
                if not success then return false, "teleport-failed" end

                task.wait(0.3)

                pcall(function()
                    CheckRemote:FireServer(cp.Index, raceName)
                end)

                if RaceState.FinishedSession == raceSession then
                    return true, "finished"
                end

                if RaceState.CancelledSession == raceSession then
                    return false, "cancelled"
                end

                if lap == totalLaps and i == totalCheckpoints then
                    task.wait(0.15)
                else
                    task.wait(CONFIG.CheckpointDelay)
                end
            else
                warn("[AutoFarm] Could not get CFrame for checkpoint " .. cp.Index)
            end
        end

        if lap < totalLaps then

            if gui then
                gui.ProgressLabel.Text = string.format("Progress: Lap %d done, starting lap %d...", lap, lap + 1)
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

local function WaitForRaceCountdown(startServerTime, gui)
    if type(startServerTime) ~= "number" or startServerTime <= 0 then
        task.wait(4)
        return
    end

    while State.Running do
        local remaining = startServerTime - workspace:GetServerTimeNow()
        if remaining <= 0.05 then
            break
        end

        if gui then
            gui.ProgressLabel.Text = string.format("Progress: Countdown %.1fs", math.max(remaining, 0))
        end

        task.wait(math.min(0.2, remaining))
    end

    task.wait(0.1)
end

local function WaitForRaceResolution(raceSession, timeout)
    local elapsed = 0
    while elapsed < timeout and State.Running do
        if RaceState.FinishedSession == raceSession then
            return "finished", RaceState.RewardAmount
        end

        if RaceState.CancelledSession == raceSession then
            return "cancelled", 0
        end

        task.wait(0.1)
        elapsed = elapsed + 0.1
    end

    return "timeout", 0
end

local function AutoFarmLoop(gui)
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
            gui.StatusLabel.Text = "Status: WAITING FOR CHARACTER"
            gui.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
            Character = Player.CharacterAdded:Wait()
            task.wait(2)
        end

        local vehicleModel, seat = GetVehicleModel()
        if not seat then
            gui.StatusLabel.Text = "Status: GET IN A VEHICLE!"
            gui.StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            while State.Running do
                task.wait(1)
                vehicleModel, seat = GetVehicleModel()
                if seat then break end
            end
            if not State.Running then break end
            task.wait(1)
        end

        gui.StatusLabel.Text = "Status: GOING TO RACE"
        gui.StatusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        gui.ProgressLabel.Text = "Progress: Teleporting..."

        local teleported = TeleportToRaceStart(raceName)
        if not teleported then
            gui.StatusLabel.Text = "Status: TELEPORT FAILED"
            gui.StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
            task.wait(3)
            continue
        end

        task.wait(3)

        gui.StatusLabel.Text = "Status: IN QUEUE (waiting " .. (RaceTimeouts[raceName] or "???") .. "s)..."
        gui.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
        gui.ProgressLabel.Text = "Progress: Waiting for race..."

        local started, startedRaceName, raceSession, startServerTime = WaitForRaceStart(queueTimeout, sessionBeforeQueue, raceName)
        if not started then
            if not State.Running then break end
            gui.StatusLabel.Text = "Status: RACE DIDN'T START, RETRYING"
            gui.StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
            pcall(function() LeaveRace:FireServer() end)
            task.wait(CONFIG.LoopDelay)
            continue
        end

        local activeRaceName = startedRaceName or raceName
        State.CurrentRaceName = activeRaceName

        gui.StatusLabel.Text = "Status: COUNTDOWN..."
        gui.StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        WaitForRaceCountdown(startServerTime, gui)

        gui.StatusLabel.Text = "Status: RACING!"
        gui.StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
        State.InRace = true

        local raceSuccess, raceResult = RunCheckpointsThroughRace(activeRaceName, gui, raceSession)

        if raceSuccess and State.Running then
            gui.StatusLabel.Text = "Status: FINISHING..."
            gui.StatusLabel.TextColor3 = Color3.fromRGB(255, 215, 0)

            local resolution, reward = WaitForRaceResolution(raceSession, 30)
            State.InRace = false

            if resolution == "finished" then
                State.RacesCompleted = State.RacesCompleted + 1
                local earned = reward > 0 and reward or estimatedReward
                State.TotalEarned = State.TotalEarned + earned

                gui.CompletedLabel.Text = "Races Done: " .. State.RacesCompleted
                gui.EarnedLabel.Text = "Estimated Earned: $" .. AddCommas(State.TotalEarned)
                gui.StatusLabel.Text = "Status: +$" .. AddCommas(earned) .. " EARNED!"
                gui.StatusLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
                print("[AutoFarm] Race #" .. State.RacesCompleted .. " complete! +$" .. AddCommas(earned))
            elseif resolution == "cancelled" then
                gui.StatusLabel.Text = "Status: RACE CANCELLED"
                gui.StatusLabel.TextColor3 = Color3.fromRGB(255, 120, 80)
            else
                gui.StatusLabel.Text = "Status: RACE TIMED OUT"
                gui.StatusLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
                pcall(function() LeaveRace:FireServer() end)
            end
        else
            State.InRace = false
            if not State.Running then break end
            if raceResult == "cancelled" then
                gui.StatusLabel.Text = "Status: RACE CANCELLED"
                gui.StatusLabel.TextColor3 = Color3.fromRGB(255, 120, 80)
            else
                gui.StatusLabel.Text = "Status: RACE FAILED, RETRYING"
                gui.StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
            pcall(function() LeaveRace:FireServer() end)
        end

        State.CurrentRaceName = nil

        if CONFIG.ClaimOfflineRewards then
            pcall(function() ClaimDrivingOffline:FireServer() end)
        end

        pcall(function()
            if _G.newDataSystem and _G.newDataSystem.Economy then
                local credits = _G.newDataSystem.Economy.Credits.Value
                gui.CreditsLabel.Text = "Balance: $" .. AddCommas(credits)
            end
        end)

        gui.ProgressLabel.Text = "Progress: Next race in " .. CONFIG.LoopDelay .. "s..."
        task.wait(CONFIG.LoopDelay)
    end

    gui.StatusLabel.Text = "Status: STOPPED"
    gui.StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    gui.ProgressLabel.Text = "Progress: --"
end

local function StartUptimeTracker(gui)
    task.spawn(function()
        while gui.Gui.Parent do
            local selectedReward = RaceRewards[CONFIG.SelectedRace] or 0
            local selectedQueue = RaceTimeouts[CONFIG.SelectedRace] or 0
            gui.RaceLabel.Text = "Selected: " .. CONFIG.SelectedRace .. " | $" .. AddCommas(selectedReward) .. " | " .. selectedQueue .. "s"
            gui.SettingsLabel.Text = string.format(
                "Delay %.1fs | Loop %ds | Height %d",
                CONFIG.CheckpointDelay,
                CONFIG.LoopDelay,
                CONFIG.TeleportHeightOffset
            )

            if State.Running and State.StartTime > 0 then
                gui.TimeLabel.Text = "Uptime: " .. FormatTime(tick() - State.StartTime)
            end
            pcall(function()
                if _G.newDataSystem and _G.newDataSystem.Economy then
                    gui.CreditsLabel.Text = "Balance: $" .. AddCommas(_G.newDataSystem.Economy.Credits.Value)
                end
            end)
            task.wait(1)
        end
    end)
end

local Gui = CreateGui()
SetupAntiAFK()
StartUptimeTracker(Gui)

local function ToggleFarm()
    State.Running = not State.Running
    if State.Running then
        Gui.ToggleBtn.Text = "STOP (F6)"
        Gui.ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Gui.StatusLabel.Text = "Status: STARTING..."
        Gui.StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        task.spawn(AutoFarmLoop, Gui)
    else
        Gui.ToggleBtn.Text = "START (F6)"
        Gui.ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 180, 80)
        State.InRace = false
        pcall(function() LeaveRace:FireServer() end)
    end
end

Gui.ToggleBtn.MouseButton1Click:Connect(ToggleFarm)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == CONFIG.ToggleKey then
        ToggleFarm()
    end
end)

Player.CharacterAdded:Connect(function(char)
    Character = char
    State.InRace = false
end)

print("=== AUTO FARM v2 LOADED ===")
print("Race: " .. CONFIG.SelectedRace .. " ($" .. AddCommas(RaceRewards[CONFIG.SelectedRace] or 0) .. "/race)")
print("Press F6 or click START. Make sure you're in a vehicle!")
