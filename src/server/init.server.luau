-- Brainrot Bay: the server. One script wires the whole game together:
-- it builds the shared Game table every module reads from, connects the
-- RemoteEvents the client talks through, and runs the one-second tick
-- that pays every player's brainrots and pushes their state to the HUD.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Economy = require(script:WaitForChild("Economy"))
local Bases = require(script:WaitForChild("Bases"))
local Spawner = require(script:WaitForChild("Spawner"))
local Wave = require(script:WaitForChild("Wave"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Game = {}
Game.Economy = Economy
Game.Bases = Bases
Game.Spawner = Spawner
Game.Wave = Wave
Game.Remotes = Remotes

-- Send one player a short message for their HUD.
function Game.notify(player, message, kind)
	Remotes:WaitForChild("Notify"):FireClient(player, message, kind or "info")
end

function Game.notifyAll(message, kind)
	Remotes:WaitForChild("Notify"):FireAllClients(message, kind or "info")
end

-- Push one player's whole state to their HUD: money, income, what they
-- own, what they carry, their lock and their base.
function Game.pushState(player)
	local ownedList = {}
	for slot, entry in ipairs(Bases.getOwned(player)) do
		if entry ~= nil then
			table.insert(ownedList, {
				slot = slot,
				name = entry.char.name,
				rarity = entry.char.rarity,
				rate = entry.rate,
			})
		end
	end
	local carriedEntry = Spawner.getCarried(player)
	local carrying = nil
	if carriedEntry ~= nil then
		carrying = carriedEntry.char.name
	end
	local expandCost = Bases.expandCost(player)
	Remotes:WaitForChild("StateUpdate"):FireClient(player, {
		money = math.floor(Economy.getMoney(player)),
		income = Economy.incomePerSecond(player),
		lifetime = math.floor(Economy.getLifetime(player)),
		rebirths = Economy.getRebirths(player),
		multiplier = Economy.rebirthMultiplier(player),
		golden = Economy.getGoldenMultiplier(),
		owned = ownedList,
		carrying = carrying,
		slots = Bases.maxSlots(player),
		expandCost = expandCost,
		lockRemaining = math.ceil(Bases.lockRemaining(player)),
		lockCooldown = math.ceil(Bases.lockCooldownRemaining(player)),
		rebirthCost = Config.REBIRTH_LIFETIME_REQUIRED,
	})
end

function Game.pushAllStates()
	for _, player in ipairs(Players:GetPlayers()) do
		Game.pushState(player)
	end
end

-- Push the tide's phase and countdown to every HUD.
function Game.pushWave()
	local phase, secondsLeft = Wave.getPhase()
	Remotes:WaitForChild("WaveUpdate"):FireAllClients(phase, secondsLeft)
end

-- The client asks the server to do things. Every handler validates:
-- the server never trusts the client about money, ownership or locks.
Remotes:WaitForChild("BuyBrainrot").OnServerEvent:Connect(function(player, padId)
	-- Buying happens through the pad's own prompt; this remote exists
	-- for clients that buy from the HUD's pad list.
	if typeof(padId) ~= "number" then
		return
	end
	Spawner.onBuyPrompt(player, padId)
	Game.pushState(player)
end)

Remotes:WaitForChild("PlaceBrainrot").OnServerEvent:Connect(function(player)
	local ok, message = Bases.placeBrainrot(player)
	Game.notify(player, message, ok and "good" or "bad")
	Game.pushState(player)
end)

Remotes:WaitForChild("SellBrainrot").OnServerEvent:Connect(function(player, slot)
	if typeof(slot) ~= "number" then
		return
	end
	local entry = Bases.getOwned(player)[slot]
	if entry == nil then
		return
	end
	Bases.onSellPrompt(player, entry)
end)

Remotes:WaitForChild("StealBrainrot").OnServerEvent:Connect(function(player, victim, slot)
	if typeof(victim) ~= "Instance" or typeof(slot) ~= "number" then
		return
	end
	local entry = Bases.getOwned(victim)[slot]
	if entry == nil then
		return
	end
	Bases.onStealPrompt(player, entry)
end)

Remotes:WaitForChild("LockBase").OnServerEvent:Connect(function(player)
	local ok, message = Bases.lockBase(player)
	Game.notify(player, message, ok and "good" or "bad")
	Game.pushState(player)
end)

Remotes:WaitForChild("ExpandBase").OnServerEvent:Connect(function(player)
	local ok, message = Bases.expandBase(player)
	Game.notify(player, message, ok and "good" or "bad")
	Game.pushState(player)
end)

Remotes:WaitForChild("Rebirth").OnServerEvent:Connect(function(player)
	local ok, message = Economy.tryRebirth(player)
	Game.notify(player, message, ok and "good" or "bad")
	Game.pushState(player)
end)

Players.PlayerAdded:Connect(function(player)
	Game.pushState(player)
end)

Economy.init(Game)
Bases.init(Game)
Spawner.init(Game)
Wave.init(Game)

-- The one-second heartbeat: pay every brainrot, refresh every lock, and
-- push every HUD its new numbers.
task.spawn(function()
	while true do
		task.wait(Config.TICK_SECONDS)
		Economy.tick()
		for _, player in ipairs(Players:GetPlayers()) do
			Bases.refreshLockPrompts(player)
			Game.pushState(player)
		end
	end
end)

print("Brainrot Bay is live. The tide comes every " .. tostring(Config.WAVE_INTERVAL) .. " seconds.")
