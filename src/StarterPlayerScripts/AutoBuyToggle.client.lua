-- StarterPlayerScripts/AutoBuyToggle (LocalScript)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local toggleEvent = ReplicatedStorage:WaitForChild("ToggleAutoBuy")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "AutoBuyGui"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(140, 40)
button.Position = UDim2.new(1, -150, 1, -50)
button.Text = "Auto Buy: OFF"
button.Parent = gui

local on = false
button.MouseButton1Click:Connect(function()
	on = not on
	button.Text = on and "Auto Buy: ON" or "Auto Buy: OFF"
	toggleEvent:FireServer(on)
end)
