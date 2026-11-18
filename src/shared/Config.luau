-- Brainrot Bay: every number the game is tuned by, in one place.
-- Change a value here and the whole game retunes: no magic numbers
-- scattered through the server scripts.

local Config = {}

-- Money
Config.START_MONEY = 100
Config.SELL_REFUND = 0.5 -- selling a brainrot returns half what it cost

-- Bases
Config.BASE_COUNT = 8
Config.BASE_RADIUS = 70 -- studs from the plaza centre to each plot centre
Config.BASE_SIZE = 24 -- the plot platform is BASE_SIZE x BASE_SIZE
Config.START_SLOTS = 6
Config.MAX_SLOTS = 12
Config.SLOTS_PER_EXPANSION = 2
-- Expand cost by expansion level (0 -> 1 costs 500, 1 -> 2 costs 2000, ...)
Config.EXPAND_BASE_COST = 500

-- Lock (the defence against stealing)
Config.LOCK_DURATION = 30 -- seconds a lock holds
Config.LOCK_COOLDOWN = 60 -- seconds before the same base can lock again

-- Spawning
Config.PAD_COUNT = 6
Config.SPAWN_INTERVAL_MIN = 8 -- seconds between spawns on one pad, at fastest
Config.SPAWN_INTERVAL_MAX = 15
Config.UNSOLD_DESPAWN = 60 -- seconds before an unbought brainrot washes away

-- The tide (the hazard)
Config.WAVE_INTERVAL = 150 -- seconds between tides
Config.WAVE_WARNING = 15 -- seconds of warning before the tide hits
Config.WAVE_SWEEP_TIME = 10 -- seconds the wall takes to cross the map

-- Events
Config.GOLDEN_HOUR_INTERVAL = 300 -- seconds between golden hours
Config.GOLDEN_HOUR_DURATION = 60
Config.GOLDEN_HOUR_MULTIPLIER = 2

-- Rebirth
Config.REBIRTH_LIFETIME_REQUIRED = 10000 -- lifetime dollars earned
Config.REBIRTH_BONUS_PER_LEVEL = 0.25 -- +25% income per rebirth
Config.REBIRTH_MAX_MULTIPLIER = 3

-- Income tick
Config.TICK_SECONDS = 1

return Config
