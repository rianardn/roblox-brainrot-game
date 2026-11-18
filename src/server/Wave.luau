-- Brainrot Bay: the tide, and the golden hour. Every few minutes the
-- sea rises and a wall of water sweeps the whole map from the bay to
-- the far shore. Anyone caught out in the open is swept back to spawn
-- and drops whatever they were carrying. Players standing on their own
-- base are safe -- so when the warning sounds, run home.
-- Between tides, a golden hour doubles every brainrot's earnings.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local Wave = {}

local Game = nil -- set by init
local waveWall = nil
local phase = "calm" -- "calm" | "warning" | "wave"
local secondsLeft = 0

function Wave.init(game)
	Game = game
	waveWall = Instance.new("Part")
	waveWall.Name = "TideWall"
	waveWall.Shape = Enum.PartType.Block
	waveWall.Size = Vector3.new(320, 30, 6)
	waveWall.Color = Color3.fromRGB(40, 120, 220)
	waveWall.Transparency = 0.45
	waveWall.Material = Enum.Material.SmoothPlastic
	waveWall.Anchored = true
	waveWall.CanCollide = false
	waveWall.CFrame = CFrame.new(0, 15, -160)
	waveWall.Parent = Workspace
	task.spawn(Wave.tideLoop)
	task.spawn(Wave.goldenHourLoop)
end

function Wave.getPhase()
	return phase, secondsLeft
end

-- Sweep one player: drop what they carry, send them back to spawn.
local function sweepPlayer(player)
	local entry = Game.Spawner.getCarried(player)
	if entry ~= nil then
		Game.Spawner.takeCarried(player)
		Game.Spawner.returnToPad(entry)
		Game.notify(player, string.format("The tide took your %s! It washed back to the plaza.", entry.char.name), "bad")
	end
	local character = player.Character
	if character == nil then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root ~= nil then
		root.CFrame = CFrame.new(0, 5, 40)
	end
	Game.notify(player, "The tide swept you back to spawn!", "bad")
	Game.pushState(player)
end

-- During the sweep, anyone not standing on their own base gets washed.
function Wave.sweep()
	for _, player in ipairs(Players:GetPlayers()) do
		if not Game.Bases.isOnOwnBase(player) then
			sweepPlayer(player)
		end
	end
end

function Wave.tideLoop()
	while true do
		-- Calm water until the next tide.
		phase = "calm"
		secondsLeft = Config.WAVE_INTERVAL
		for _ = 1, Config.WAVE_INTERVAL do
			task.wait(1)
			secondsLeft -= 1
			Game.pushWave()
		end
		-- The warning: fifteen seconds to get home.
		phase = "warning"
		secondsLeft = Config.WAVE_WARNING
		Game.notifyAll("THE TIDE IS COMING! Get back to your base!", "bad")
		for _ = 1, Config.WAVE_WARNING do
			task.wait(1)
			secondsLeft -= 1
			Game.pushWave()
		end
		-- The wall crosses the map, sweeping everyone in the open.
		phase = "wave"
		secondsLeft = Config.WAVE_SWEEP_TIME
		Game.notifyAll("THE TIDE IS HERE!", "bad")
		local tween = TweenService:Create(
			waveWall,
			TweenInfo.new(Config.WAVE_SWEEP_TIME, Enum.EasingStyle.Linear),
			{ CFrame = CFrame.new(0, 15, 160) }
		)
		tween:Play()
		for _ = 1, Config.WAVE_SWEEP_TIME do
			task.wait(1)
			secondsLeft -= 1
			Game.pushWave()
			Wave.sweep()
		end
		tween:Cancel()
		waveWall.CFrame = CFrame.new(0, 15, -160)
	end
end

-- A golden hour doubles every brainrot's earnings for a minute.
function Wave.goldenHourLoop()
	while true do
		task.wait(Config.GOLDEN_HOUR_INTERVAL)
		Game.Economy.setGoldenMultiplier(Config.GOLDEN_HOUR_MULTIPLIER)
		Game.notifyAll("GOLDEN HOUR! Every brainrot earns DOUBLE for a minute!", "good")
		task.wait(Config.GOLDEN_HOUR_DURATION)
		Game.Economy.setGoldenMultiplier(1)
		Game.notifyAll("Golden hour is over. The bay returns to normal.", "info")
	end
end

return Wave
