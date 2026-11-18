-- Brainrot Bay: the bases. Eight plots ring the plaza; the first eight
-- players each claim one. A base holds the brainrots its owner placed,
-- each on a slot, earning money every second. Bases can be locked
-- against thieves, and expanded for more slots.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local Bases = {}

local Game = nil -- set by init
local plots = {} -- [index] = { centre = Vector3, owner = player | nil }
local owned = {} -- [player] = array of entries, indexed by slot
local expansions = {} -- [player] = expansion level (0..3)
local lockUntil = {} -- [player] = os.clock() when the lock ends
local lockCooldownUntil = {} -- [player] = os.clock() when locking is allowed again

-- Twelve slot offsets on a plot, in a 4 by 3 grid. The first six are
-- open from the start; expansions unlock the rest, two at a time.
local SLOT_OFFSETS = {
	Vector3.new(-7.5, 0, -6), Vector3.new(-2.5, 0, -6), Vector3.new(2.5, 0, -6), Vector3.new(7.5, 0, -6),
	Vector3.new(-7.5, 0, 0), Vector3.new(-2.5, 0, 0), Vector3.new(2.5, 0, 0), Vector3.new(7.5, 0, 0),
	Vector3.new(-7.5, 0, 6), Vector3.new(-2.5, 0, 6), Vector3.new(2.5, 0, 6), Vector3.new(7.5, 0, 6),
}

function Bases.init(game)
	Game = game
	for i = 1, Config.BASE_COUNT do
		local angle = math.rad((i - 1) * (360 / Config.BASE_COUNT))
		local x = Config.BASE_RADIUS * math.cos(angle)
		local z = Config.BASE_RADIUS * math.sin(angle)
		plots[i] = { centre = Vector3.new(x, 0, z), owner = nil }
	end
	Players.PlayerAdded:Connect(Bases.playerAdded)
	Players.PlayerRemoving:Connect(Bases.playerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		Bases.playerAdded(player)
	end
end

function Bases.playerAdded(player)
	owned[player] = {}
	expansions[player] = 0
	lockUntil[player] = 0
	lockCooldownUntil[player] = 0
	for _, plot in ipairs(plots) do
		if plot.owner == nil then
			plot.owner = player
			Game.notify(player, string.format("This is your base, %s! Bring brainrots home.", player.Name), "good")
			return
		end
	end
	Game.notify(player, "Every base is taken right now -- you can still buy and steal!", "bad")
end

function Bases.playerRemoving(player)
	Bases.clearBase(player)
	owned[player] = nil
	expansions[player] = nil
	lockUntil[player] = nil
	lockCooldownUntil[player] = nil
	for _, plot in ipairs(plots) do
		if plot.owner == player then
			plot.owner = nil
		end
	end
end

-- The plot a player owns, or nil.
function Bases.getPlot(player)
	for _, plot in ipairs(plots) do
		if plot.owner == player then
			return plot
		end
	end
	return nil
end

-- How many slots this player's base has right now.
function Bases.maxSlots(player)
	return Config.START_SLOTS + (expansions[player] or 0) * Config.SLOTS_PER_EXPANSION
end

function Bases.getOwned(player)
	return owned[player] or {}
end

-- The world position of a slot on a player's base.
function Bases.slotPosition(player, slot)
	local plot = Bases.getPlot(player)
	local offset = SLOT_OFFSETS[slot]
	if plot == nil or offset == nil then
		return nil
	end
	-- The platform top is y = 2; the body is 2 tall, so its centre rides at y = 3.
	return Vector3.new(plot.centre.X + offset.X, 3, plot.centre.Z + offset.Z)
end

-- Is the player's character standing on their own plot? The tide only
-- spares players who made it home.
function Bases.isOnOwnBase(player)
	local plot = Bases.getPlot(player)
	if plot == nil then
		return false
	end
	local character = player.Character
	if character == nil then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return false
	end
	local pos = root.Position
	local half = Config.BASE_SIZE / 2
	return math.abs(pos.X - plot.centre.X) <= half
		and math.abs(pos.Z - plot.centre.Z) <= half
		and pos.Y > 1
end

local function makePrompt(parent, actionText, objectText, keyCode)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = keyCode
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = parent
	return prompt
end

-- Put the brainrot the player is carrying onto a free slot of their base.
-- Returns (success, message).
function Bases.placeBrainrot(player)
	local plot = Bases.getPlot(player)
	if plot == nil then
		return false, "You have no base to place it on."
	end
	local entry = Game.Spawner.takeCarried(player)
	if entry == nil then
		return false, "You are not carrying a brainrot."
	end
	local list = owned[player]
	local slot = nil
	for i = 1, Bases.maxSlots(player) do
		if list[i] == nil then
			slot = i
			break
		end
	end
	if slot == nil then
		Game.Spawner.giveCarried(player, entry)
		return false, "Your base is full! Expand it or sell a brainrot."
	end
	local position = Bases.slotPosition(player, slot)
	if position == nil then
		Game.Spawner.giveCarried(player, entry)
		return false, "Your base is full! Expand it or sell a brainrot."
	end
	entry.state = "placed"
	entry.owner = player
	entry.slot = slot
	list[slot] = entry
	Game.Spawner.anchorModel(entry.model, CFrame.new(position))
	-- A sell prompt for the owner, a steal prompt for everyone else.
	entry.sellPrompt = makePrompt(entry.model.PrimaryPart, "Sell", entry.char.name, Enum.KeyCode.F)
	entry.sellPrompt.Triggered:Connect(function(triggerPlayer)
		Bases.onSellPrompt(triggerPlayer, entry)
	end)
	entry.stealPrompt = makePrompt(entry.model.PrimaryPart, "Steal", entry.char.name, Enum.KeyCode.E)
	entry.stealPrompt.Triggered:Connect(function(triggerPlayer)
		Bases.onStealPrompt(triggerPlayer, entry)
	end)
	Bases.refreshLockPrompts(player)
	return true,
		string.format("%s is home! It earns $%d a second.", entry.char.name, entry.rate)
end

function Bases.onSellPrompt(player, entry)
	if entry.owner ~= player or entry.state ~= "placed" then
		return
	end
	local refund = math.floor(entry.cost * Config.SELL_REFUND)
	Bases.removeEntry(player, entry)
	entry.model:Destroy()
	Game.Economy.addMoney(player, refund)
	Game.notify(player, string.format("Sold %s for $%d.", entry.char.name, refund), "good")
	Game.pushState(player)
end

function Bases.onStealPrompt(player, entry)
	if entry.state ~= "placed" then
		return
	end
	if entry.owner == player then
		Game.notify(player, "That one is already yours.", "info")
		return
	end
	if entry.owner == nil then
		return
	end
	if Bases.isLocked(entry.owner) then
		Game.notify(player, string.format("%s's base is LOCKED. Nice try.", entry.owner.Name), "bad")
		return
	end
	if Game.Spawner.getCarried(player) ~= nil then
		Game.notify(player, "Your hands are full -- place what you are carrying first.", "bad")
		return
	end
	Bases.removeEntry(entry.owner, entry)
	Game.Spawner.giveCarried(player, entry)
	Game.notify(player, string.format("You stole %s! RUN HOME before the tide or its owner catches you.", entry.char.name), "good")
	Game.notify(entry.owner, string.format("%s stole your %s!", player.Name, entry.char.name), "bad")
	Game.pushState(player)
	Game.pushState(entry.owner)
end

-- Take a placed entry off its base and destroy its model and prompts.
-- The entry itself is returned so the caller can reuse it (stealing).
function Bases.removeEntry(owner, entry)
	local list = owned[owner]
	if list ~= nil and entry.slot ~= nil then
		list[entry.slot] = nil
	end
	if entry.sellPrompt ~= nil then
		entry.sellPrompt:Destroy()
		entry.sellPrompt = nil
	end
	if entry.stealPrompt ~= nil then
		entry.stealPrompt:Destroy()
		entry.stealPrompt = nil
	end
	entry.state = "gone"
	entry.owner = nil
	entry.slot = nil
end

-- Wipe a base clean: every placed brainrot is destroyed. Used by rebirth
-- and when a player leaves.
function Bases.clearBase(player)
	local list = owned[player]
	if list == nil then
		return
	end
	for _, entry in ipairs(list) do
		if entry ~= nil and entry.model ~= nil then
			Bases.removeEntry(player, entry)
			entry.model:Destroy()
		end
	end
	owned[player] = {}
end

-- Lock this base against stealing. Returns (success, message).
function Bases.lockBase(player)
	if Bases.getPlot(player) == nil then
		return false, "You have no base to lock."
	end
	local now = os.clock()
	if now < (lockCooldownUntil[player] or 0) then
		return false,
			string.format("Lock recharges in %d seconds.", math.ceil((lockCooldownUntil[player] or 0) - now))
	end
	lockUntil[player] = now + Config.LOCK_DURATION
	lockCooldownUntil[player] = now + Config.LOCK_DURATION + Config.LOCK_COOLDOWN
	Bases.refreshLockPrompts(player)
	return true, string.format("Base LOCKED for %d seconds. Thieves, beware.", Config.LOCK_DURATION)
end

function Bases.isLocked(player)
	return os.clock() < (lockUntil[player] or 0)
end

function Bases.lockRemaining(player)
	return math.max(0, (lockUntil[player] or 0) - os.clock())
end

function Bases.lockCooldownRemaining(player)
	return math.max(0, (lockCooldownUntil[player] or 0) - os.clock())
end

-- Steal prompts are only usable while the owner's base is unlocked.
function Bases.refreshLockPrompts(player)
	local locked = Bases.isLocked(player)
	for _, entry in ipairs(owned[player] or {}) do
		if entry ~= nil and entry.stealPrompt ~= nil then
			entry.stealPrompt.Enabled = not locked
		end
	end
end

-- Spend money for two more slots. Returns (success, message).
function Bases.expandBase(player)
	local level = expansions[player] or 0
	if Bases.maxSlots(player) >= Config.MAX_SLOTS then
		return false, "Your base is already at its biggest."
	end
	local cost = Config.EXPAND_BASE_COST * (level + 1) * (level + 1)
	if not Game.Economy.spendMoney(player, cost) then
		return false, string.format("Expanding costs $%d. Save up!", cost)
	end
	expansions[player] = level + 1
	return true,
		string.format("Base expanded! You now have %d slots.", Bases.maxSlots(player))
end

function Bases.expandCost(player)
	local level = expansions[player] or 0
	if Bases.maxSlots(player) >= Config.MAX_SLOTS then
		return nil
	end
	return Config.EXPAND_BASE_COST * (level + 1) * (level + 1)
end

return Bases
