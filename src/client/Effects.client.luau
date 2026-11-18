-- Brainrot Bay: the effects. Small feedback that makes the game feel
-- alive: a green "+$X" that floats up from the money counter every
-- time the income tick lands, and a full-screen red flash when the
-- tide warning sounds, so nobody misses it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBayEffects"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- A red flash that covers the screen for a beat when the tide warns.
local flash = Instance.new("Frame")
flash.Name = "TideFlash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.fromRGB(255, 40, 40)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = gui

local lastMoney = nil

-- Every state update carries the new money total. The difference since
-- the last update is the income that just landed: float it up.
Remotes:WaitForChild("StateUpdate").OnClientEvent:Connect(function(state)
	if lastMoney == nil then
		lastMoney = state.money
		return
	end
	local gained = state.money - lastMoney
	lastMoney = state.money
	if gained <= 0 then
		return
	end
	local popup = Instance.new("TextLabel")
	popup.Name = "MoneyPopup"
	popup.AnchorPoint = Vector2.new(0.5, 0)
	popup.Position = UDim2.new(0.5, 0, 0, 96)
	popup.Size = UDim2.fromOffset(200, 28)
	popup.BackgroundTransparency = 1
	popup.Text = string.format("+$%d", gained)
	popup.TextColor3 = Color3.fromRGB(120, 255, 140)
	popup.TextSize = 22
	popup.Font = Enum.Font.GothamBold
	popup.TextStrokeTransparency = 0.3
	popup.Parent = gui
	local tween = TweenService:Create(
		popup,
		TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0, 56), TextTransparency = 1, TextStrokeTransparency = 1 }
	)
	tween:Play()
	tween.Completed:Connect(function()
		popup:Destroy()
	end)
end)

-- Flash the screen once when the warning phase starts.
local warned = false
Remotes:WaitForChild("WaveUpdate").OnClientEvent:Connect(function(phase)
	if phase == "warning" and not warned then
		warned = true
		flash.BackgroundTransparency = 0.75
		local tween = TweenService:Create(flash, TweenInfo.new(1.5), { BackgroundTransparency = 1 })
		tween:Play()
	elseif phase ~= "warning" then
		warned = false
	end
end)
