-- Brainrot Bay: the economy. One table per player holds their money,
-- their lifetime earnings and their rebirths. The income tick runs here:
-- every second each player's placed brainrots pay out, multiplied by
-- their rebirth bonus and by the golden-hour event when it is live.

local Players = game:GetService("Players")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local Economy = {}

local Game = nil -- set by init: { Bases = ..., Remotes = ..., notify = fn }
local money = {} -- [player] = dollars
local lifetime = {} -- [player] = dollars earned in total, ever
local rebirths = {} -- [player] = rebirth count
local goldenMultiplier = 1

function Economy.init(game)
	Game = game
	Players.PlayerAdded:Connect(Economy.playerAdded)
	Players.PlayerRemoving:Connect(Economy.playerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		Economy.playerAdded(player)
	end
end

function Economy.playerAdded(player)
	money[player] = Config.START_MONEY
	lifetime[player] = 0
	rebirths[player] = 0
end

function Economy.playerRemoving(player)
	money[player] = nil
	lifetime[player] = nil
	rebirths[player] = nil
end

function Economy.getMoney(player)
	return money[player] or 0
end

function Economy.getLifetime(player)
	return lifetime[player] or 0
end

function Economy.getRebirths(player)
	return rebirths[player] or 0
end

-- The income multiplier from rebirths alone, before golden hour.
function Economy.rebirthMultiplier(player)
	local level = rebirths[player] or 0
	local mult = 1 + level * Config.REBIRTH_BONUS_PER_LEVEL
	if mult > Config.REBIRTH_MAX_MULTIPLIER then
		mult = Config.REBIRTH_MAX_MULTIPLIER
	end
	return mult
end

function Economy.setGoldenMultiplier(value)
	goldenMultiplier = value
end

function Economy.getGoldenMultiplier()
	return goldenMultiplier
end

-- What this player earns per second right now, from their placed
-- brainrots, after every multiplier. Bases owns the brainrot list.
function Economy.incomePerSecond(player)
	local total = 0
	for _, entry in ipairs(Game.Bases.getOwned(player)) do
		total += entry.rate
	end
	return total * Economy.rebirthMultiplier(player) * goldenMultiplier
end

function Economy.addMoney(player, amount)
	money[player] = (money[player] or 0) + amount
	if amount > 0 then
		lifetime[player] = (lifetime[player] or 0) + amount
	end
end

-- Spend money if the player can afford it. Returns true on success.
function Economy.spendMoney(player, amount)
	local current = money[player] or 0
	if current < amount then
		return false
	end
	money[player] = current - amount
	return true
end

-- One income tick for every player in the game.
function Economy.tick()
	for _, player in ipairs(Players:GetPlayers()) do
		local income = Economy.incomePerSecond(player)
		if income > 0 then
			Economy.addMoney(player, income * Config.TICK_SECONDS)
		end
	end
end

-- Rebirth: wipe the wallet and the base, keep a permanent income bonus.
-- Returns (success, message).
function Economy.tryRebirth(player)
	local earned = lifetime[player] or 0
	if earned < Config.REBIRTH_LIFETIME_REQUIRED then
		return false,
			string.format(
				"Rebirth needs $%d earned in total. You have earned $%d.",
				Config.REBIRTH_LIFETIME_REQUIRED,
				math.floor(earned)
			)
	end
	Game.Bases.clearBase(player)
	money[player] = Config.START_MONEY
	rebirths[player] = (rebirths[player] or 0) + 1
	local mult = Economy.rebirthMultiplier(player)
	return true,
		string.format(
			"REBIRTH! Your brainrots now earn x%.2f. The bay fears you.",
			mult
		)
end

return Economy
