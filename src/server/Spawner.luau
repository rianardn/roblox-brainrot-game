-- Brainrot Bay: the spawner. Absurd brainrots wash up on the six pads
-- around the plaza, each with a price tag. A player buys one, carries
-- it home on their head, and places it on their base. Drop it in the
-- tide and it washes back to a pad for someone else to grab.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local Spawner = {}

local Game = nil -- set by init
local pads = {} -- [padId] = { position = Vector3, entry = entry | nil }
local carried = {} -- [player] = entry | nil

local PAD_RADIUS = 12 -- pads ring the plaza centre at this distance

function Spawner.init(game)
	Game = game
	for i = 1, Config.PAD_COUNT do
		local angle = math.rad((i - 1) * (360 / Config.PAD_COUNT) + 30)
		pads[i] = {
			position = Vector3.new(PAD_RADIUS * math.cos(angle), 2, PAD_RADIUS * math.sin(angle)),
			entry = nil,
		}
	end
	Players.PlayerRemoving:Connect(function(player)
		local entry = carried[player]
		if entry ~= nil then
			Spawner.returnToPad(entry)
			carried[player] = nil
		end
	end)
	task.spawn(Spawner.spawnLoop)
end

-- Build the 3D model of one brainrot: a coloured body, a head, eyes,
-- and a floating label with its name, rarity and money per second.
function Spawner.buildBrainrotModel(entry)
	local char = entry.char
	local model = Instance.new("Model")
	model.Name = char.id

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(2, 2, 1)
	body.Color = char.color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = true
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Color = char.color:Lerp(Color3.new(1, 1, 1), 0.35)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Position = body.Position + Vector3.new(0, 1.7, 0)
	head.Parent = model

	-- Two eyes, so it stares at you while it earns.
	for _, side in ipairs({ -0.4, 0.4 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.35, 0.35, 0.35)
		eye.Color = Color3.new(0.05, 0.05, 0.05)
		eye.Material = Enum.Material.SmoothPlastic
		eye.Anchored = true
		eye.CanCollide = false
		eye.Position = head.Position + Vector3.new(side, 0.2, 0.75)
		eye.Parent = model
	end

	-- The label every player reads: name, rarity, dollars per second.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(140, 64)
	billboard.StudsOffset = Vector3.new(0, 3.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0, 22)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = char.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Parent = billboard

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "Rarity"
	rarityLabel.Position = UDim2.new(0, 0, 0, 22)
	rarityLabel.Size = UDim2.new(1, 0, 0, 18)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = char.rarity
	rarityLabel.TextColor3 = BrainrotData.rarityColor(char.rarity)
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextStrokeTransparency = 0.2
	rarityLabel.Parent = billboard

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "Rate"
	rateLabel.Position = UDim2.new(0, 0, 0, 40)
	rateLabel.Size = UDim2.new(1, 0, 0, 20)
	rateLabel.BackgroundTransparency = 1
	if entry.mutation.name == "None" then
		rateLabel.Text = string.format("$%d/s", entry.rate)
	else
		rateLabel.Text = string.format("$%d/s  %s x%d", entry.rate, entry.mutation.name, entry.mutation.multiplier)
	end
	rateLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.TextStrokeTransparency = 0.2
	rateLabel.Parent = billboard

	model.PrimaryPart = body
	model.Parent = Workspace
	return model
end

-- Move a model to a position and anchor every part of it.
function Spawner.anchorModel(model, cframe)
	model:PivotTo(cframe)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = true
		end
	end
end

-- Weld a brainrot to a player's head so they carry it home. Every part
-- of the model is welded to the body first, so the head and eyes ride
-- along instead of falling off mid-carry.
function Spawner.weldToPlayer(entry, player)
	local character = player.Character
	if character == nil then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return false
	end
	local body = entry.model.PrimaryPart
	entry.welds = {}
	for _, part in ipairs(entry.model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			if part ~= body then
				local weld = Instance.new("Weld")
				weld.Name = "PartWeld"
				weld.Part0 = body
				weld.Part1 = part
				weld.C0 = body.CFrame:Inverse() * part.CFrame
				weld.Parent = body
				table.insert(entry.welds, weld)
			end
		end
	end
	local weld = Instance.new("Weld")
	weld.Name = "CarryWeld"
	weld.Part0 = root
	weld.Part1 = body
	weld.C0 = CFrame.new(0, 3.5, 0)
	weld.Parent = body
	table.insert(entry.welds, weld)
	return true
end

function Spawner.unweld(entry)
	if entry.welds ~= nil then
		for _, weld in ipairs(entry.welds) do
			weld:Destroy()
		end
		entry.welds = nil
	end
end

function Spawner.getCarried(player)
	return carried[player]
end

function Spawner.giveCarried(player, entry)
	carried[player] = entry
	entry.state = "carried"
	entry.owner = player
	Spawner.weldToPlayer(entry, player)
	Game.pushState(player)
end

-- Take the carried entry off a player (placing it). Returns nil when
-- the player carries nothing.
function Spawner.takeCarried(player)
	local entry = carried[player]
	if entry == nil then
		return nil
	end
	carried[player] = nil
	Spawner.unweld(entry)
	return entry
end

-- A carried brainrot dropped in the tide washes back to a random empty
-- pad, with its buy prompt back on, for someone else to grab.
function Spawner.returnToPad(entry)
	Spawner.unweld(entry)
	local empty = {}
	for id, pad in ipairs(pads) do
		if pad.entry == nil then
			table.insert(empty, id)
		end
	end
	if #empty == 0 then
		entry.model:Destroy()
		return
	end
	local padId = empty[math.random(1, #empty)]
	Spawner.placeOnPad(entry, padId)
end

function Spawner.placeOnPad(entry, padId)
	local pad = pads[padId]
	pad.entry = entry
	entry.state = "pad"
	entry.padId = padId
	entry.owner = nil
	entry.slot = nil
	Spawner.anchorModel(entry.model, CFrame.new(pad.position))
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy " .. entry.char.name
	prompt.ObjectText = string.format("$%d", entry.cost)
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = entry.model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		Spawner.onBuyPrompt(player, padId)
	end)
	entry.buyPrompt = prompt
end

function Spawner.onBuyPrompt(player, padId)
	local pad = pads[padId]
	local entry = pad.entry
	if entry == nil or entry.state ~= "pad" then
		return
	end
	if carried[player] ~= nil then
		Game.notify(player, "Your hands are full -- place what you are carrying first.", "bad")
		return
	end
	if not Game.Economy.spendMoney(player, entry.cost) then
		Game.notify(player, string.format("You need $%d for %s. Keep earning!", entry.cost, entry.char.name), "bad")
		return
	end
	pad.entry = nil
	if entry.buyPrompt ~= nil then
		entry.buyPrompt:Destroy()
		entry.buyPrompt = nil
	end
	Spawner.giveCarried(player, entry)
	Game.notify(player, string.format("You bought %s! Carry it home to your base.", entry.char.name), "good")
end

-- A fresh brainrot washes up on an empty pad.
function Spawner.spawnOne(padId)
	local pad = pads[padId]
	if pad.entry ~= nil then
		return
	end
	local char = BrainrotData.randomCharacter()
	local mutation = BrainrotData.rollMutation()
	local entry = {
		char = char,
		mutation = mutation,
		rate = BrainrotData.rateFor(char, mutation),
		cost = BrainrotData.costFor(char, mutation),
		model = nil,
		state = "pad",
		padId = padId,
		owner = nil,
		slot = nil,
	}
	entry.model = Spawner.buildBrainrotModel(entry)
	Spawner.placeOnPad(entry, padId)
	task.delay(Config.UNSOLD_DESPAWN, function()
		if pad.entry == entry and entry.state == "pad" then
			pad.entry = nil
			if entry.buyPrompt ~= nil then
				entry.buyPrompt:Destroy()
			end
			entry.model:Destroy()
		end
	end)
end

-- Keep the pads stocked: every few seconds, fill one empty pad.
function Spawner.spawnLoop()
	while true do
		task.wait(math.random(Config.SPAWN_INTERVAL_MIN, Config.SPAWN_INTERVAL_MAX))
		local empty = {}
		for id, pad in ipairs(pads) do
			if pad.entry == nil then
				table.insert(empty, id)
			end
		end
		if #empty > 0 then
			Spawner.spawnOne(empty[math.random(1, #empty)])
		end
	end
end

return Spawner
