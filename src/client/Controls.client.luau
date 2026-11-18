-- Brainrot Bay: the controls. Keyboard shortcuts for the actions that
-- matter in a hurry, and the "place what you are carrying" key. The
-- proximity prompts keep their own keys (E to buy, E to steal, F to
-- sell); these are the extras a player reaches for without a mouse.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- L locks the base. The tide gives fifteen seconds of warning; a lock
-- takes one keypress, so a player who is home can defend in time.
local function lockBase(_action, state)
	if state == Enum.UserInputState.Begin then
		Remotes:WaitForChild("LockBase"):FireServer()
	end
	return Enum.ContextActionResult.Pass
end
ContextActionService:BindAction("BrainrotBayLock", lockBase, false, Enum.KeyCode.L)

-- Q places the brainrot you are carrying on your base, the same as the
-- prompt on the plot. One key, no mouse, for the run home.
local function placeBrainrot(_action, state)
	if state == Enum.UserInputState.Begin then
		Remotes:WaitForChild("PlaceBrainrot"):FireServer()
	end
	return Enum.ContextActionResult.Pass
end
ContextActionService:BindAction("BrainrotBayPlace", placeBrainrot, false, Enum.KeyCode.Q)

-- R asks for a rebirth. The server still checks the lifetime total,
-- so a stray keypress can never spend anything.
local function rebirth(_action, state)
	if state == Enum.UserInputState.Begin then
		Remotes:WaitForChild("Rebirth"):FireServer()
	end
	return Enum.ContextActionResult.Pass
end
ContextActionService:BindAction("BrainrotBayRebirth", rebirth, false, Enum.KeyCode.R)
