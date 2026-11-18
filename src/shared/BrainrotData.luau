-- Brainrot Bay: the brainrot cast. Every character is an original absurd
-- invention of this game -- none of them are borrowed from Steal a
-- Brainrot or any other game. Each one earns money every second while it
-- sits on a player's base.

local BrainrotData = {}

BrainrotData.RARITIES = {
	Common = { order = 1, color = Color3.fromRGB(200, 200, 200), weight = 45 },
	Rare = { order = 2, color = Color3.fromRGB(90, 160, 255), weight = 30 },
	Epic = { order = 3, color = Color3.fromRGB(180, 90, 255), weight = 15 },
	Legendary = { order = 4, color = Color3.fromRGB(255, 200, 40), weight = 7 },
	Mythic = { order = 5, color = Color3.fromRGB(255, 80, 140), weight = 3 },
}

-- A mutation multiplies both what a brainrot earns and what it costs.
BrainrotData.MUTATIONS = {
	{ name = "None", multiplier = 1, chance = 0.90, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Golden", multiplier = 2, chance = 0.08, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", multiplier = 4, chance = 0.02, color = Color3.fromRGB(120, 220, 255) },
}

-- The cast. rate is dollars per second, cost is what the pad asks.
-- colour is the body colour of the 3D model Spawner builds.
BrainrotData.CHARACTERS = {
	{
		id = "ConeWizard",
		name = "Cone Wizard",
		rarity = "Common",
		rate = 1,
		cost = 25,
		color = Color3.fromRGB(255, 140, 40),
		blurb = "A traffic cone that learned magic. Mostly traffic.",
	},
	{
		id = "DiscoPigeon",
		name = "Disco Pigeon",
		rarity = "Common",
		rate = 2,
		cost = 50,
		color = Color3.fromRGB(140, 140, 150),
		blurb = "It only coos in 4/4 time. The dance floor is wherever it stands.",
	},
	{
		id = "VendingDestiny",
		name = "Vending Machine of Destiny",
		rarity = "Rare",
		rate = 5,
		cost = 150,
		color = Color3.fromRGB(220, 60, 60),
		blurb = "It knows what you want before you do. It is always sold out of it.",
	},
	{
		id = "SirToaster",
		name = "Sir Reginald the Toaster",
		rarity = "Rare",
		rate = 8,
		cost = 250,
		color = Color3.fromRGB(200, 190, 180),
		blurb = "Knighted for services to breakfast. Burns everything on purpose.",
	},
	{
		id = "CaptainCouch",
		name = "Captain Couch",
		rarity = "Epic",
		rate = 15,
		cost = 500,
		color = Color3.fromRGB(90, 140, 220),
		blurb = "Sailed the seven living rooms. Never once got up.",
	},
	{
		id = "WifiRouterDoom",
		name = "The WiFi Router of Doom",
		rarity = "Epic",
		rate = 22,
		cost = 750,
		color = Color3.fromRGB(60, 60, 70),
		blurb = "Its signal reaches the afterlife. The password is 'password'.",
	},
	{
		id = "GrandmaWifi",
		name = "Grandma's Wi-Fi Password",
		rarity = "Legendary",
		rate = 40,
		cost = 1500,
		color = Color3.fromRGB(255, 220, 180),
		blurb = "Written on a sticky note in 2009. Worth more than gold now.",
	},
	{
		id = "LastSlice",
		name = "The Last Slice of Pizza",
		rarity = "Legendary",
		rate = 60,
		cost = 2500,
		color = Color3.fromRGB(255, 200, 90),
		blurb = "Everyone wants it. No one dares take it. It knows.",
	},
	{
		id = "ChairmanMeow",
		name = "Chairman Meow",
		rarity = "Mythic",
		rate = 120,
		cost = 5000,
		color = Color3.fromRGB(40, 40, 45),
		blurb = "A cat in a suit. Owns the bay. Owns you. You just don't know it yet.",
	},
	{
		id = "MoonSock",
		name = "The Moon's Left Sock",
		rarity = "Mythic",
		rate = 200,
		cost = 9000,
		color = Color3.fromRGB(220, 230, 255),
		blurb = "It fell off the moon in 1969. It has been waiting for you.",
	},
}

local byId = {}
for _, char in ipairs(BrainrotData.CHARACTERS) do
	byId[char.id] = char
end

function BrainrotData.getCharacter(id)
	return byId[id]
end

function BrainrotData.rarityColor(rarity)
	local entry = BrainrotData.RARITIES[rarity]
	if entry then
		return entry.color
	end
	return Color3.fromRGB(255, 255, 255)
end

-- Pick a character weighted by its rarity's weight, so commons wash up
-- often and mythics almost never do.
function BrainrotData.randomCharacter()
	local total = 0
	for _, rarity in pairs(BrainrotData.RARITIES) do
		total += rarity.weight
	end
	local roll = math.random() * total
	local acc = 0
	local pickedRarity = "Common"
	for name, rarity in pairs(BrainrotData.RARITIES) do
		acc += rarity.weight
		if roll <= acc then
			pickedRarity = name
			break
		end
	end
	local pool = {}
	for _, char in ipairs(BrainrotData.CHARACTERS) do
		if char.rarity == pickedRarity then
			table.insert(pool, char)
		end
	end
	return pool[math.random(1, #pool)]
end

function BrainrotData.rollMutation()
	local roll = math.random()
	local acc = 0
	for _, mutation in ipairs(BrainrotData.MUTATIONS) do
		acc += mutation.chance
		if roll <= acc then
			return mutation
		end
	end
	return BrainrotData.MUTATIONS[1]
end

-- What a brainrot earns and costs once its mutation is applied.
function BrainrotData.rateFor(char, mutation)
	return char.rate * mutation.multiplier
end

function BrainrotData.costFor(char, mutation)
	return char.cost * mutation.multiplier
end

return BrainrotData
