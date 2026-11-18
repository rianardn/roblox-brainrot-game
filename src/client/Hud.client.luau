-- Brainrot Bay: the HUD. Everything the player reads while they play:
-- their money and income, the tide countdown, the brainrots they own,
-- and the buttons for locking, expanding and rebirthing. It stays clear
-- of the top-left corner, where Roblox puts its own menu buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBayGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(parent, name, text, size, color, position, anchor)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = anchor or Vector2.new(0, 0)
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextSize = 20
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.3
	label.Parent = parent
	return label
end

-- Money, top centre: the number the whole game revolves around.
local moneyLabel = makeLabel(
	gui,
	"Money",
	"$0",
	UDim2.fromOffset(320, 44),
	Color3.fromRGB(255, 215, 0),
	UDim2.new(0.5, 0, 0, 8),
	Vector2.new(0.5, 0)
)
moneyLabel.TextSize = 32

local incomeLabel = makeLabel(
	gui,
	"Income",
	"+$0/s",
	UDim2.fromOffset(320, 24),
	Color3.fromRGB(120, 255, 140),
	UDim2.new(0.5, 0, 0, 52),
	Vector2.new(0.5, 0)
)
incomeLabel.TextSize = 18

local carryingLabel = makeLabel(
	gui,
	"Carrying",
	"",
	UDim2.fromOffset(320, 24),
	Color3.fromRGB(160, 220, 255),
	UDim2.new(0.5, 0, 0, 76),
	Vector2.new(0.5, 0)
)
carryingLabel.TextSize = 18

-- The tide countdown, top right.
local waveLabel = makeLabel(
	gui,
	"Wave",
	"Next tide: --:--",
	UDim2.fromOffset(220, 28),
	Color3.fromRGB(140, 200, 255),
	UDim2.new(1, -12, 0, 12),
	Vector2.new(1, 0)
)
waveLabel.TextSize = 18
waveLabel.TextXAlignment = Enum.TextXAlignment.Right

-- Notifications, centre top, fading in and out.
local notifyLabel = makeLabel(
	gui,
	"Notify",
	"",
	UDim2.fromOffset(560, 30),
	Color3.new(1, 1, 1),
	UDim2.new(0.5, 0, 0, 108),
	Vector2.new(0.5, 0)
)
notifyLabel.TextSize = 20

-- The brainrots on this player's base, bottom left.
local ownedTitle = makeLabel(
	gui,
	"OwnedTitle",
	"YOUR BRAINROTS",
	UDim2.fromOffset(260, 24),
	Color3.new(1, 1, 1),
	UDim2.new(0, 12, 1, -148),
	Vector2.new(0, 0)
)
ownedTitle.TextSize = 16
ownedTitle.TextXAlignment = Enum.TextXAlignment.Left

local ownedList = Instance.new("ScrollingFrame")
ownedList.Name = "OwnedList"
ownedList.Position = UDim2.new(0, 12, 1, -122)
ownedList.Size = UDim2.fromOffset(260, 110)
ownedList.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
ownedList.BackgroundTransparency = 0.35
ownedList.BorderSizePixel = 0
ownedList.ScrollBarThickness = 4
ownedList.CanvasSize = UDim2.new(0, 0, 0, 0)
ownedList.AutomaticCanvasSize = Enum.AutomaticSize.Y
ownedList.Parent = gui

local ownedLayout = Instance.new("UIListLayout")
ownedLayout.Padding = UDim.new(0, 2)
ownedLayout.Parent = ownedList

-- Buttons, bottom right.
local function makeButton(name, text, position)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 0)
	button.Position = position
	button.Size = UDim2.fromOffset(230, 36)
	button.BackgroundColor3 = Color3.fromRGB(30, 40, 70)
	button.BorderSizePixel = 0
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 16
	button.Font = Enum.Font.GothamBold
	button.Parent = gui
	return button
end

local lockButton = makeButton("LockButton", "Lock Base (L)", UDim2.new(1, -12, 1, -132))
local expandButton = makeButton("ExpandButton", "Expand Base", UDim2.new(1, -12, 1, -88))
local rebirthButton = makeButton("RebirthButton", "Rebirth", UDim2.new(1, -12, 1, -44))

lockButton.MouseButton1Click:Connect(function()
	Remotes:WaitForChild("LockBase"):FireServer()
end)
expandButton.MouseButton1Click:Connect(function()
	Remotes:WaitForChild("ExpandBase"):FireServer()
end)
rebirthButton.MouseButton1Click:Connect(function()
	Remotes:WaitForChild("Rebirth"):FireServer()
end)

-- The whole state arrives in one table, once a second.
Remotes:WaitForChild("StateUpdate").OnClientEvent:Connect(function(state)
	moneyLabel.Text = string.format("$%d", state.money)
	local incomeText = string.format("+$%d/s", math.floor(state.income))
	if state.golden and state.golden > 1 then
		incomeText = incomeText .. "  GOLDEN HOUR x2!"
	end
	if state.multiplier and state.multiplier > 1 then
		incomeText = incomeText .. string.format("  (rebirth x%.2f)", state.multiplier)
	end
	incomeLabel.Text = incomeText
	if state.carrying ~= nil and state.carrying ~= "" then
		carryingLabel.Text = "Carrying: " .. state.carrying .. " -- take it to your base!"
	else
		carryingLabel.Text = ""
	end
	if state.lockRemaining and state.lockRemaining > 0 then
		lockButton.Text = string.format("Locked (%ds)", state.lockRemaining)
	elseif state.lockCooldown and state.lockCooldown > 0 then
		lockButton.Text = string.format("Lock recharges (%ds)", state.lockCooldown)
	else
		lockButton.Text = "Lock Base (L)"
	end
	if state.expandCost ~= nil then
		expandButton.Text = string.format("Expand Base ($%d)", state.expandCost)
	else
		expandButton.Text = "Base is max size"
	end
	rebirthButton.Text = string.format("Rebirth ($%d earned)", state.rebirthCost or 10000)
	-- Rebuild the owned list.
	for _, child in ipairs(ownedList:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	if #state.owned == 0 then
		local empty = makeLabel(ownedList, "Empty", "No brainrots yet -- go to the plaza!", UDim2.new(1, 0, 0, 22), Color3.fromRGB(180, 180, 180), UDim2.new(0, 0, 0, 0), Vector2.new(0, 0))
		empty.TextSize = 14
		empty.TextXAlignment = Enum.TextXAlignment.Left
	else
		for _, entry in ipairs(state.owned) do
			local line = makeLabel(
				ownedList,
				"Owned" .. tostring(entry.slot),
				string.format("#%d %s  $%d/s", entry.slot, entry.name, entry.rate),
				UDim2.new(1, 0, 0, 22),
				Color3.new(1, 1, 1),
				UDim2.new(0, 0, 0, 0),
				Vector2.new(0, 0)
			)
			line.TextSize = 14
			line.TextXAlignment = Enum.TextXAlignment.Left
		end
	end
end)

Remotes:WaitForChild("WaveUpdate").OnClientEvent:Connect(function(phase, secondsLeft)
	if phase == "calm" then
		waveLabel.Text = string.format("Next tide: %d:%02d", math.floor(secondsLeft / 60), secondsLeft % 60)
		waveLabel.TextColor3 = Color3.fromRGB(140, 200, 255)
	elseif phase == "warning" then
		waveLabel.Text = string.format("TIDE IN %ds -- GET HOME!", secondsLeft)
		waveLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	else
		waveLabel.Text = "THE TIDE IS HERE!"
		waveLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	end
end)

local notifyToken = 0
Remotes:WaitForChild("Notify").OnClientEvent:Connect(function(message, kind)
	notifyToken += 1
	local token = notifyToken
	notifyLabel.Text = message
	if kind == "good" then
		notifyLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	elseif kind == "bad" then
		notifyLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	else
		notifyLabel.TextColor3 = Color3.new(1, 1, 1)
	end
	task.delay(3, function()
		if token == notifyToken then
			notifyLabel.Text = ""
		end
	end)
end)
