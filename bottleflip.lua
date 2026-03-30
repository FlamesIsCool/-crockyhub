local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

WindUI:AddTheme({
    Name = "Dark",
    Accent = Color3.fromHex("#00ff88"),
    Background = Color3.fromHex("#1a1a1a"),
    Outline = Color3.fromHex("#333333"),
    Text = Color3.fromHex("#ffffff"),
    Button = Color3.fromHex("#00aa60"),
    Icon = Color3.fromHex("#00ff88"),
})

WindUI:SetTheme("Dark")

local Window = WindUI:CreateWindow({
    Title = "CrockyHub - BottleFlip!",
    Icon = "zap",
    Size = UDim2.fromOffset(320, 280),
    Resizable = true,
})

local Tab = Window:Tab({
    Icon = "play",
    Title = "Main",
})

local autoClaimConn = nil

Tab:Button({
    Title = "Auto Green",
    Desc = "Autp Flips in Green Zone",
    Icon = "circle",
    Callback = function()
        pcall(function()
            ReplicatedStorage.Modules.EventManagerClient.ServerEvent:FireServer("ExecuteThrow", {Result = "Green"})
        end)
        WindUI:Notify({Title = "Fired", Content = "Auto Green", Duration = 1.5, Icon = "check-circle"})
    end
})

local autoClaimToggle = Tab:Toggle({
    Title = "Inf Cash",
    Desc = "Auto ClaimReward",
    Icon = "dollar-sign",
    Value = false,
    Callback = function(enabled)
        if enabled then
            autoClaimConn = RunService.Heartbeat:Connect(function()
                pcall(function()
                    ReplicatedStorage.Modules.EventManagerClient.ServerEvent:FireServer("ClaimReward")
                end)
            end)
        else
            if autoClaimConn then
                autoClaimConn:Disconnect()
                autoClaimConn = nil
            end
        end
    end
})

Tab:Button({
    Title = "Warning",
    Desc = "Don't spam",
    Icon = "alert-triangle",
    Callback = function()
        WindUI:Notify({Title = "Warning", Content = "Don't spam - breaks game", Duration = 3, Icon = "alert-triangle"})
    end
})

Window.OnClose = function()
    if autoClaimConn then
        autoClaimConn:Disconnect()
    end
end
