-- BrainrotCatalog: every fact about the cast, the rarities, the mutations and
-- the rebirth ladder. Pure data plus small lookups; it holds no services and
-- no state, so the server and the client both require it.
-- Every character here is an original invention for Brainrot Bazaar.

local BrainrotCatalog = {}

BrainrotCatalog.GAME_NAME = "Brainrot Bazaar"
BrainrotCatalog.GAME_TAGLINE = "Buy brainrots. Stack your base. Survive the wave."

BrainrotCatalog.START_CASH = 100
BrainrotCatalog.BASE_COUNT = 8
BrainrotCatalog.SLOTS_PER_BASE = 10
BrainrotCatalog.BELT_SPAWN_SECONDS = 4
BrainrotCatalog.BELT_SPEED = 6
BrainrotCatalog.BELT_START_X = -90
BrainrotCatalog.BELT_END_X = 90
BrainrotCatalog.BELT_Z = 0
BrainrotCatalog.BELT_TOP_Y = 1
BrainrotCatalog.MAX_BELT_BRAINROTS = 12
BrainrotCatalog.LOCK_BASE_SECONDS = 60
BrainrotCatalog.SLAP_RANGE = 9
BrainrotCatalog.SLAP_COOLDOWN = 3
BrainrotCatalog.STEAL_SLOW = 0.7
BrainrotCatalog.TSUNAMI_EVERY_SECONDS = 240
BrainrotCatalog.TSUNAMI_FIRST_SECONDS = 90
BrainrotCatalog.TSUNAMI_WARN_SECONDS = 20
BrainrotCatalog.TSUNAMI_SPEED = 40
BrainrotCatalog.PITY_LEGENDARY_SECONDS = 300
BrainrotCatalog.PITY_MYTHIC_SECONDS = 900

-- A part recipe is { shape, size, offset, colourRole } with an optional
-- fifth entry, transparency. Roles are "body", "accent" and "detail" and map
-- to the character's three colours. Shapes: "Ball", "Block", "Cylinder"
-- (built vertical) and "Wedge". Offsets are relative to the body centre,
-- front facing +Z. The factory scales every size and offset by the scale.

BrainrotCatalog.RARITIES = {
	{ name = "Common", color = { 0.78, 0.78, 0.78 }, weight = 45 },
	{ name = "Rare", color = { 0.25, 0.6, 1 }, weight = 28 },
	{ name = "Epic", color = { 0.65, 0.35, 1 }, weight = 14 },
	{ name = "Legendary", color = { 1, 0.65, 0 }, weight = 7 },
	{ name = "Mythic", color = { 1, 0.25, 0.35 }, weight = 3.5 },
	{ name = "Brainrot God", color = { 1, 0.9, 0.2 }, weight = 1.5 },
	{ name = "Secret", color = { 0.3, 1, 0.7 }, weight = 0.7 },
	{ name = "OG", color = { 1, 0.4, 0.9 }, weight = 0.3 },
}

BrainrotCatalog.CHARACTERS = {
	{
		id = "waddles", name = "Waddles McTeapot", rarity = 1, price = 25, income = 1,
		quip = "Steeped in chaos.", scale = 1,
		body = { 1, 0.8, 0.2 }, accent = { 1, 0.55, 0.1 }, detail = { 1, 0.95, 0.8 },
		parts = {
			{ "Ball", { 2.6, 2.6, 2.6 }, { 0, 0, 0 }, "body" },
			{ "Wedge", { 1.2, 0.7, 1 }, { 0, 0.2, 1.4 }, "accent" },
			{ "Cylinder", { 0.5, 1.4, 1.4 }, { 0, 1.5, 0 }, "detail" },
			{ "Block", { 1.2, 0.5, 0.5 }, { 1.4, 0.4, 0 }, "accent" },
			{ "Block", { 0.4, 1.2, 1.4 }, { -1.3, 0, 0 }, "detail" },
		},
	},
	{
		id = "barksalot", name = "Sir Barksalot", rarity = 1, price = 50, income = 2,
		quip = "Pops up when least expected.", scale = 1.05,
		body = { 0.8, 0.6, 0.4 }, accent = { 0.45, 0.3, 0.15 }, detail = { 0.8, 0.8, 0.85 },
		parts = {
			{ "Block", { 2.4, 2.2, 2.6 }, { 0, 0, 0 }, "body" },
			{ "Block", { 0.8, 1, 0.4 }, { -0.7, 1.5, 0 }, "accent" },
			{ "Block", { 0.8, 1, 0.4 }, { 0.7, 1.5, 0 }, "accent" },
			{ "Ball", { 0.6, 0.6, 0.6 }, { 0, 0.3, 1.4 }, "accent" },
			{ "Block", { 1.6, 0.5, 0.3 }, { 0, 1, -1.4 }, "detail" },
		},
	},
	{
		id = "crumb", name = "Captain Crumb", rarity = 2, price = 200, income = 6,
		quip = "Your snacks are his now.", scale = 1.1,
		body = { 0.95, 0.95, 0.95 }, accent = { 1, 0.6, 0.1 }, detail = { 0.2, 0.4, 0.9 },
		parts = {
			{ "Ball", { 2.6, 2.4, 2.8 }, { 0, 0, 0 }, "body" },
			{ "Wedge", { 1.1, 0.6, 1 }, { 0, 0.1, 1.5 }, "accent" },
			{ "Cylinder", { 0.8, 1.8, 1.8 }, { 0, 1.6, 0 }, "detail" },
			{ "Block", { 1.6, 0.3, 1.2 }, { -1.8, 0.3, 0 }, "body" },
			{ "Block", { 1.6, 0.3, 1.2 }, { 1.8, 0.3, 0 }, "body" },
		},
	},
	{
		id = "puddles", name = "Puddles the Platypus", rarity = 2, price = 500, income = 12,
		quip = "Rain or shine, he collects.", scale = 1.1,
		body = { 0.55, 0.4, 0.25 }, accent = { 1, 0.65, 0.2 }, detail = { 0.9, 0.2, 0.2 },
		parts = {
			{ "Ball", { 2.8, 2.2, 3 }, { 0, 0, 0 }, "body" },
			{ "Block", { 1.6, 0.5, 1 }, { 0, -0.2, 1.8 }, "accent" },
			{ "Cylinder", { 2.6, 0.25, 0.25 }, { 0.8, 2, 0 }, "body" },
			{ "Ball", { 3.2, 1, 3.2 }, { 0.8, 3.4, 0 }, "detail" },
			{ "Block", { 1.4, 0.4, 1.2 }, { 0, 0, -1.9 }, "body" },
		},
	},
	{
		id = "dumpling", name = "Duchess Dumpling", rarity = 3, price = 1500, income = 35,
		quip = "Steamed to purr-fection.", scale = 1.15,
		body = { 1, 0.92, 0.8 }, accent = { 1, 0.6, 0.7 }, detail = { 0.75, 0.6, 0.35 },
		parts = {
			{ "Ball", { 2.8, 2.6, 2.8 }, { 0, 0, 0 }, "body" },
			{ "Wedge", { 0.9, 0.9, 0.6 }, { -0.8, 1.5, 0 }, "body" },
			{ "Wedge", { 0.9, 0.9, 0.6 }, { 0.8, 1.5, 0 }, "body" },
			{ "Cylinder", { 0.9, 2.2, 2.2 }, { 0, 1.9, 0 }, "detail" },
			{ "Block", { 1.4, 0.4, 0.4 }, { 1.7, 0.3, -0.4 }, "accent" },
		},
	},
	{
		id = "pickles", name = "Sergeant Pickles", rarity = 3, price = 3000, income = 60,
		quip = "Dill with it.", scale = 1.2,
		body = { 0.3, 0.75, 0.3 }, accent = { 0.15, 0.5, 0.2 }, detail = { 0.8, 0.95, 0.8 },
		parts = {
			{ "Ball", { 2.8, 2.4, 2.8 }, { 0, 0, 0 }, "body" },
			{ "Ball", { 0.9, 0.9, 0.9 }, { -0.8, 1.5, 0.4 }, "accent" },
			{ "Ball", { 0.9, 0.9, 0.9 }, { 0.8, 1.5, 0.4 }, "accent" },
			{ "Cylinder", { 2.4, 1.8, 1.8 }, { -1.9, 0.4, 0 }, "detail", 0.5 },
			{ "Block", { 1, 0.4, 1.4 }, { -0.8, -1.2, 0.6 }, "accent" },
			{ "Block", { 1, 0.4, 1.4 }, { 0.8, -1.2, 0.6 }, "accent" },
		},
	},
	{
		id = "quokka", name = "Queen Quokka", rarity = 4, price = 12000, income = 200,
		quip = "Happiest monarch alive.", scale = 1.3,
		body = { 0.6, 0.45, 0.3 }, accent = { 1, 0.85, 0.25 }, detail = { 0.95, 0.95, 0.95 },
		parts = {
			{ "Ball", { 2.8, 2.8, 2.8 }, { 0, 0, 0 }, "body" },
			{ "Block", { 0.5, 0.8, 0.5 }, { -0.6, 1.7, 0 }, "accent" },
			{ "Block", { 0.5, 1, 0.5 }, { 0, 1.8, 0 }, "accent" },
			{ "Block", { 0.5, 0.8, 0.5 }, { 0.6, 1.7, 0 }, "accent" },
			{ "Cylinder", { 0.9, 1.2, 1.2 }, { 1.8, 0.2, 0.6 }, "detail" },
		},
	},
	{
		id = "llamacorn", name = "Lord Llamacorn", rarity = 4, price = 25000, income = 400,
		quip = "Soft serve, hard stare.", scale = 1.35,
		body = { 0.95, 0.9, 0.8 }, accent = { 1, 0.65, 0.75 }, detail = { 0.8, 0.6, 0.35 },
		parts = {
			{ "Block", { 2.4, 2.6, 3 }, { 0, 0, 0 }, "body" },
			{ "Cylinder", { 2.2, 1, 1 }, { 0, 2.2, 0.8 }, "body" },
			{ "Wedge", { 1, 1.4, 1 }, { 0, 3.6, 0.8 }, "detail" },
			{ "Ball", { 1.2, 1.2, 1.2 }, { 0, 4.5, 0.8 }, "accent" },
			{ "Block", { 0.6, 1.2, 0.6 }, { -0.9, -1.6, 0.8 }, "body" },
			{ "Block", { 0.6, 1.2, 0.6 }, { 0.9, -1.6, 0.8 }, "body" },
		},
	},
	{
		id = "penguini", name = "Professor Penguini", rarity = 5, price = 80000, income = 1200,
		quip = "Caffeinated and calculating.", scale = 1.4,
		body = { 0.15, 0.15, 0.2 }, accent = { 0.95, 0.95, 0.95 }, detail = { 0.75, 0.75, 0.8 },
		parts = {
			{ "Ball", { 2.8, 3.2, 2.8 }, { 0, 0, 0 }, "body" },
			{ "Ball", { 2, 2.4, 1.2 }, { 0, -0.3, 1 }, "accent" },
			{ "Block", { 1.6, 2, 1.2 }, { -2, -0.2, 0 }, "detail" },
			{ "Wedge", { 0.8, 0.6, 0.6 }, { -0.5, 0.9, 1.3 }, "detail" },
			{ "Wedge", { 0.8, 0.6, 0.6 }, { 0.5, 0.9, 1.3 }, "detail" },
		},
	},
	{
		id = "butterfrog", name = "Baroness Butterfrog", rarity = 5, price = 150000, income = 2000,
		quip = "Spreads joy. And butter.", scale = 1.4,
		body = { 1, 0.8, 0.2 }, accent = { 1, 0.95, 0.5 }, detail = { 0.95, 0.95, 0.95 },
		parts = {
			{ "Cylinder", { 2.6, 1.2, 1.2 }, { 0, 0, 0 }, "body" },
			{ "Block", { 2.4, 0.3, 1.6 }, { -1.9, 0.6, 0 }, "accent", 0.3 },
			{ "Block", { 2.4, 0.3, 1.6 }, { 1.9, 0.6, 0 }, "accent", 0.3 },
			{ "Cylinder", { 0.6, 2.6, 2.6 }, { 0, -1.6, 0 }, "detail" },
			{ "Ball", { 0.8, 0.8, 0.8 }, { 0, 1.7, 0 }, "accent" },
		},
	},
	{
		id = "guacamole", name = "El Guacamole Grande", rarity = 6, price = 500000, income = 6000,
		quip = "Extra. Always extra.", scale = 1.6,
		body = { 0.35, 0.7, 0.25 }, accent = { 0.2, 0.5, 0.15 }, detail = { 1, 0.85, 0.3 },
		parts = {
			{ "Ball", { 3.2, 2.8, 3.4 }, { 0, 0, 0 }, "body" },
			{ "Ball", { 3.6, 2, 3 }, { 0, 0.6, -0.6 }, "accent" },
			{ "Cylinder", { 1, 3.6, 3.6 }, { 0, -1.9, 0 }, "accent" },
			{ "Wedge", { 1, 1.2, 0.5 }, { -1.2, 1.8, 0.8 }, "detail" },
			{ "Wedge", { 1, 1.2, 0.5 }, { 1.2, 1.8, 0.8 }, "detail" },
		},
	},
	{
		id = "hootington", name = "Sir Hootington", rarity = 6, price = 1000000, income = 12000,
		quip = "Time is money. Literally.", scale = 1.6,
		body = { 0.5, 0.35, 0.2 }, accent = { 1, 0.9, 0.3 }, detail = { 0.4, 0.25, 0.12 },
		parts = {
			{ "Ball", { 3, 3.2, 3 }, { 0, 0, 0 }, "body" },
			{ "Ball", { 0.9, 0.9, 0.9 }, { -0.8, 0.8, 1.3 }, "accent" },
			{ "Ball", { 0.9, 0.9, 0.9 }, { 0.8, 0.8, 1.3 }, "accent" },
			{ "Block", { 1.8, 4.4, 1 }, { 0, 0.4, -2 }, "detail" },
			{ "Cylinder", { 2, 0.3, 0.3 }, { 0, 0.2, -1.4 }, "accent" },
			{ "Ball", { 0.8, 0.8, 0.8 }, { 0, -0.9, -1.4 }, "accent" },
		},
	},
	{
		id = "zorp", name = "Zorp the Unbothered", rarity = 7, price = 5000000, income = 50000,
		quip = "Vibing since forever.", scale = 1.7,
		body = { 1, 0.6, 0.75 }, accent = { 0.7, 0.4, 1 }, detail = { 0.85, 0.7, 1 },
		parts = {
			{ "Ball", { 3, 2.8, 3.2 }, { 0, 0, 0 }, "body" },
			{ "Ball", { 0.8, 1.2, 0.8 }, { -1.6, 0.8, 0 }, "accent" },
			{ "Ball", { 0.8, 1.2, 0.8 }, { 1.6, 0.8, 0 }, "accent" },
			{ "Ball", { 0.8, 1.2, 0.8 }, { -1.6, 0.8, -0.8 }, "accent" },
			{ "Ball", { 0.8, 1.2, 0.8 }, { 1.6, 0.8, -0.8 }, "accent" },
			{ "Cylinder", { 2.2, 1.4, 1.4 }, { 0, 2.4, 0 }, "detail", 0.4 },
		},
	},
	{
		id = "nebula", name = "Nebula Noodle", rarity = 7, price = 12000000, income = 100000,
		quip = "Slurps stardust.", scale = 1.8,
		body = { 0.55, 0.3, 0.9 }, accent = { 0.4, 0.9, 1 }, detail = { 0.9, 0.25, 0.25 },
		parts = {
			{ "Ball", { 3.2, 3, 3.2 }, { 0, 0, 0 }, "body" },
			{ "Cylinder", { 2.4, 0.5, 0.5 }, { -1.2, -1.8, 0.6 }, "accent" },
			{ "Cylinder", { 2.4, 0.5, 0.5 }, { 1.2, -1.8, 0.6 }, "accent" },
			{ "Cylinder", { 2.4, 0.5, 0.5 }, { -1.2, -1.8, -0.6 }, "accent" },
			{ "Cylinder", { 2.4, 0.5, 0.5 }, { 1.2, -1.8, -0.6 }, "accent" },
			{ "Cylinder", { 1, 3.8, 3.8 }, { 0, -2.6, 0 }, "detail" },
		},
	},
	{
		id = "pancake", name = "The First Pancake", rarity = 8, price = 50000000, income = 350000,
		quip = "Older than breakfast.", scale = 2,
		body = { 0.45, 0.55, 0.25 }, accent = { 0.85, 0.7, 0.45 }, detail = { 0.4, 0.2, 0.08 },
		parts = {
			{ "Ball", { 3.6, 2.6, 4 }, { 0, 0, 0 }, "body" },
			{ "Ball", { 3, 1.8, 3.4 }, { 0, 1, 0 }, "accent" },
			{ "Cylinder", { 0.5, 2.6, 2.6 }, { 0, 2.2, 0 }, "accent" },
			{ "Cylinder", { 0.5, 2.3, 2.3 }, { 0, 2.7, 0 }, "accent" },
			{ "Cylinder", { 0.5, 2, 2 }, { 0, 3.2, 0 }, "accent" },
			{ "Ball", { 1.2, 0.8, 1.2 }, { 0, 3.7, 0 }, "detail" },
		},
	},
	{
		id = "grandma", name = "Grandma Giga", rarity = 8, price = 150000000, income = 1000000,
		quip = "Knits. Naps. Earns.", scale = 2.1,
		body = { 0.55, 0.4, 0.28 }, accent = { 0.5, 0.32, 0.16 }, detail = { 1, 0.6, 0.7 },
		parts = {
			{ "Block", { 3.4, 2.8, 4.2 }, { 0, 0, 0 }, "body" },
			{ "Block", { 3, 2.4, 0.6 }, { 0, 1.6, -2.2 }, "accent" },
			{ "Wedge", { 1.6, 1, 2.4 }, { -1.4, -1.6, 0 }, "accent" },
			{ "Wedge", { 1.6, 1, 2.4 }, { 1.4, -1.6, 0 }, "accent" },
			{ "Cylinder", { 1.6, 0.25, 0.25 }, { 1.2, 0.6, 1.6 }, "detail" },
			{ "Ball", { 1, 1, 1 }, { -1.2, 0.4, 1.8 }, "detail" },
		},
	},
}

-- Mutations roll on spawn; at most one per brainrot. Chances are checked in
-- order, rarest first, so the table reads top-down by value.
BrainrotCatalog.MUTATIONS = {
	{ name = "Rainbow", chance = 0.0025, multiplier = 10, color = { 1, 0.3, 0.8 } },
	{ name = "Divine", chance = 0.005, multiplier = 10, color = { 1, 1, 1 } },
	{ name = "Diamond", chance = 0.04, multiplier = 1.5, color = { 0.6, 0.9, 1 } },
	{ name = "Gold", chance = 0.08, multiplier = 1.25, color = { 1, 0.85, 0.2 } },
}

-- Each rebirth needs the cash and at least one owned brainrot of the
-- required rarity or better. It resets cash and the base, and the multiplier
-- is the ladder value itself, not a running product.
BrainrotCatalog.REBIRTHS = {
	{ cash = 25000, needRarity = 3, multiplier = 2, lockBonus = 10, speedBonus = 2 },
	{ cash = 250000, needRarity = 4, multiplier = 3, lockBonus = 10, speedBonus = 2 },
	{ cash = 2500000, needRarity = 5, multiplier = 5, lockBonus = 10, speedBonus = 2 },
	{ cash = 25000000, needRarity = 6, multiplier = 8, lockBonus = 10, speedBonus = 2 },
	{ cash = 250000000, needRarity = 7, multiplier = 12, lockBonus = 10, speedBonus = 2 },
}

BrainrotCatalog.BASE_COLORS = {
	{ 1, 0.25, 0.25 },
	{ 1, 0.6, 0.15 },
	{ 1, 0.9, 0.2 },
	{ 0.25, 0.85, 0.35 },
	{ 0.25, 0.55, 1 },
	{ 0.65, 0.35, 1 },
	{ 1, 0.45, 0.8 },
	{ 0.2, 0.9, 0.9 },
}

-- Fallback base centres, used only if the static Bases folder cannot be read.
-- The live game reads the real floor positions from the workspace instead.
-- Floor centres of the eight bases in the widened bazaar layout: pitch 44,
-- 20 studs of open ground between adjacent 24-wide floors.
-- Gates sit 11.5 studs belt-side of each centre, so gate Z is +/-18.5.
BrainrotCatalog.BASE_CENTERS = {
	{ x = -66, z = -30 },
	{ x = -22, z = -30 },
	{ x = 22, z = -30 },
	{ x = 66, z = -30 },
	{ x = -66, z = 30 },
	{ x = -22, z = 30 },
	{ x = 22, z = 30 },
	{ x = 66, z = 30 },
}

local charactersById = {}
for _, character in ipairs(BrainrotCatalog.CHARACTERS) do
	charactersById[character.id] = character
end

local mutationsByName = {}
for _, mutation in ipairs(BrainrotCatalog.MUTATIONS) do
	mutationsByName[mutation.name] = mutation
end

function BrainrotCatalog.RollRarityWithPity(pityLegendary, pityMythic)
	local minRarity = 1
	if pityMythic then
		minRarity = 5
	elseif pityLegendary then
		minRarity = 4
	end
	local total = 0
	for index = minRarity, #BrainrotCatalog.RARITIES do
		total = total + BrainrotCatalog.RARITIES[index].weight
	end
	local roll = math.random() * total
	for index = minRarity, #BrainrotCatalog.RARITIES do
		roll = roll - BrainrotCatalog.RARITIES[index].weight
		if roll <= 0 then
			return index
		end
	end
	return minRarity
end

function BrainrotCatalog.RollMutation()
	for _, mutation in ipairs(BrainrotCatalog.MUTATIONS) do
		if math.random() < mutation.chance then
			return mutation.name
		end
	end
	return nil
end

function BrainrotCatalog.GetCharacter(characterId)
	return charactersById[characterId]
end

function BrainrotCatalog.GetRandomCharacterOfRarity(rarityIndex)
	local pool = {}
	for _, character in ipairs(BrainrotCatalog.CHARACTERS) do
		if character.rarity == rarityIndex then
			table.insert(pool, character)
		end
	end
	if #pool == 0 then
		return BrainrotCatalog.CHARACTERS[1]
	end
	return pool[math.random(#pool)]
end

function BrainrotCatalog.GetMutation(mutationName)
	if mutationName == nil then
		return nil
	end
	return mutationsByName[mutationName]
end

function BrainrotCatalog.GetMutationMultiplier(mutationName)
	local mutation = BrainrotCatalog.GetMutation(mutationName)
	if mutation == nil then
		return 1
	end
	return mutation.multiplier
end

function BrainrotCatalog.GetRarityName(rarityIndex)
	local rarity = BrainrotCatalog.RARITIES[rarityIndex]
	if rarity == nil then
		return "Common"
	end
	return rarity.name
end

function BrainrotCatalog.GetRarityColor(rarityIndex)
	local rarity = BrainrotCatalog.RARITIES[rarityIndex]
	if rarity == nil then
		return Color3.new(0.78, 0.78, 0.78)
	end
	return Color3.new(rarity.color[1], rarity.color[2], rarity.color[3])
end

function BrainrotCatalog.GetRebirthRequirement(rebirthLevel)
	return BrainrotCatalog.REBIRTHS[rebirthLevel + 1]
end

function BrainrotCatalog.GetIncomeWithMutation(character, mutationName)
	return character.income * BrainrotCatalog.GetMutationMultiplier(mutationName)
end

return BrainrotCatalog
