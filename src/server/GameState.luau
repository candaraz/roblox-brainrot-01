-- GameState: the one place the server keeps state. Cash, bases, locks,
-- rebirths and every brainrot record live here; the controllers and the main
-- server script ask this module, never a copy of their own. Client scripts
-- never require it: they learn state through the StateSync remote.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(game:GetService("ReplicatedStorage"):WaitForChild("BrainrotCatalog"))

local GameState = {}

local playerStates = {}
local baseOwners = {}
local beltBrainrots = {}
local baseCenters = {}
local slotPads = {}
local gateParts = {}
local signLabels = {}
local nextUid = 1

local function makeEmptyState(player, baseIndex)
	return {
		player = player,
		cash = BrainrotCatalog.START_CASH,
		rebirthLevel = 0,
		multiplier = 1,
		baseIndex = baseIndex,
		owned = {},
		lockUntil = 0,
		slapReadyAt = 0,
		lastLegendaryAt = os.clock(),
		lastMythicAt = os.clock(),
	}
end

function GameState.TickEarnings(seconds)
	for _, state in pairs(playerStates) do
		local income = GameState.GetIncomePerSecond(state.player)
		if income > 0 then
			state.cash = state.cash + income * seconds
		end
	end
end

function GameState.GetIncomePerSecond(player)
	local state = playerStates[player]
	if state == nil then
		return 0
	end
	local total = 0
	for _, record in pairs(state.owned) do
		if record.status == "placed" then
			local character = BrainrotCatalog.GetCharacter(record.characterId)
			total = total + BrainrotCatalog.GetIncomeWithMutation(character, record.mutation)
		end
	end
	return total * state.multiplier
end

function GameState.AssignBase(player)
	for index = 1, BrainrotCatalog.BASE_COUNT do
		if baseOwners[index] == nil then
			baseOwners[index] = player
			playerStates[player] = makeEmptyState(player, index)
			return index
		end
	end
	playerStates[player] = makeEmptyState(player, nil)
	return nil
end

function GameState.GetState(player)
	return playerStates[player]
end

function GameState.RemovePlayer(player)
	local state = playerStates[player]
	if state ~= nil and state.baseIndex ~= nil then
		baseOwners[state.baseIndex] = nil
	end
	playerStates[player] = nil
end

function GameState.AddCash(player, amount)
	local state = playerStates[player]
	if state ~= nil then
		state.cash = state.cash + amount
	end
end

function GameState.SpendCash(player, amount)
	local state = playerStates[player]
	if state == nil or state.cash < amount then
		return false
	end
	state.cash = state.cash - amount
	return true
end

function GameState.NextUid()
	local uid = "br" .. tostring(nextUid)
	nextUid = nextUid + 1
	return uid
end

function GameState.RegisterBeltBrainrot(record)
	table.insert(beltBrainrots, record)
end

function GameState.GetBeltBrainrots()
	return beltBrainrots
end

function GameState.RemoveBeltBrainrot(record)
	for index, candidate in ipairs(beltBrainrots) do
		if candidate == record then
			table.remove(beltBrainrots, index)
			return
		end
	end
end

function GameState.FindBrainrotByUid(uid)
	for _, record in ipairs(beltBrainrots) do
		if record.uid == uid then
			return record
		end
	end
	for _, state in pairs(playerStates) do
		local record = state.owned[uid]
		if record ~= nil then
			return record
		end
	end
	return nil
end

function GameState.FindFreeSlot(player)
	local state = playerStates[player]
	if state == nil or state.baseIndex == nil then
		return nil
	end
	local taken = {}
	for _, record in pairs(state.owned) do
		if record.slotIndex ~= nil then
			taken[record.slotIndex] = true
		end
	end
	for slot = 1, BrainrotCatalog.SLOTS_PER_BASE do
		if not taken[slot] then
			return slot
		end
	end
	return nil
end

function GameState.GrantBrainrot(player, record, slotIndex)
	local state = playerStates[player]
	if state == nil then
		return false
	end
	record.owner = player
	record.baseIndex = state.baseIndex
	record.slotIndex = slotIndex
	state.owned[record.uid] = record
	return true
end

function GameState.ReleaseBrainrot(record)
	if record.owner ~= nil then
		local state = playerStates[record.owner]
		if state ~= nil then
			state.owned[record.uid] = nil
		end
	end
	record.owner = nil
	record.baseIndex = nil
	record.slotIndex = nil
end

function GameState.GetOwnedCount(player)
	local state = playerStates[player]
	if state == nil then
		return 0
	end
	local count = 0
	for _ in pairs(state.owned) do
		count = count + 1
	end
	return count
end

function GameState.GetOwnedCountsByCharacter(player)
	local counts = {}
	local state = playerStates[player]
	if state == nil then
		return counts
	end
	for _, record in pairs(state.owned) do
		counts[record.characterId] = (counts[record.characterId] or 0) + 1
	end
	return counts
end

function GameState.OwnsRarityOrBetter(player, rarityIndex)
	local state = playerStates[player]
	if state == nil then
		return false
	end
	for _, record in pairs(state.owned) do
		local character = BrainrotCatalog.GetCharacter(record.characterId)
		if character ~= nil and character.rarity >= rarityIndex then
			return true
		end
	end
	return false
end

function GameState.SetBaseLock(player, seconds)
	local state = playerStates[player]
	if state == nil then
		return false
	end
	state.lockUntil = os.clock() + seconds
	return true
end

function GameState.GetLockRemaining(player)
	local state = playerStates[player]
	if state == nil then
		return 0
	end
	return math.max(0, state.lockUntil - os.clock())
end

function GameState.IsBaseLocked(baseIndex)
	local owner = baseOwners[baseIndex]
	if owner == nil then
		return false
	end
	return GameState.GetLockRemaining(owner) > 0
end

function GameState.GetBaseOwner(baseIndex)
	return baseOwners[baseIndex]
end

function GameState.GetLockSecondsFor(player)
	local state = playerStates[player]
	local level = 0
	if state ~= nil then
		level = state.rebirthLevel
	end
	return BrainrotCatalog.LOCK_BASE_SECONDS + level * 10
end

function GameState.GetWalkSpeedFor(player)
	local state = playerStates[player]
	local level = 0
	if state ~= nil then
		level = state.rebirthLevel
	end
	return 16 + level * 2
end

function GameState.PerformRebirth(player)
	local state = playerStates[player]
	if state == nil then
		return false, "No state yet."
	end
	local requirement = BrainrotCatalog.GetRebirthRequirement(state.rebirthLevel)
	if requirement == nil then
		return false, "Max rebirth reached."
	end
	if state.cash < requirement.cash then
		return false, "Not enough cash for rebirth."
	end
	if not GameState.OwnsRarityOrBetter(player, requirement.needRarity) then
		return false, "Rebirth needs a " .. BrainrotCatalog.GetRarityName(requirement.needRarity) .. " or better."
	end
	for _, record in pairs(state.owned) do
		if record.model ~= nil then
			record.model:Destroy()
		end
	end
	state.owned = {}
	state.cash = BrainrotCatalog.START_CASH
	state.rebirthLevel = state.rebirthLevel + 1
	state.multiplier = requirement.multiplier
	state.lockUntil = 0
	return true, "Reborn! Income x" .. tostring(state.multiplier) .. "."
end

function GameState.NoteRaritySpawned(rarityIndex)
	local now = os.clock()
	for _, state in pairs(playerStates) do
		if rarityIndex >= 4 then
			state.lastLegendaryAt = now
		end
		if rarityIndex >= 5 then
			state.lastMythicAt = now
		end
	end
end

function GameState.GetPityFlags()
	local now = os.clock()
	local pityLegendary = false
	local pityMythic = false
	local anyPlayer = false
	for _, state in pairs(playerStates) do
		anyPlayer = true
		if now - state.lastLegendaryAt >= BrainrotCatalog.PITY_LEGENDARY_SECONDS then
			pityLegendary = true
		end
		if now - state.lastMythicAt >= BrainrotCatalog.PITY_MYTHIC_SECONDS then
			pityMythic = true
		end
	end
	if not anyPlayer then
		return false, false
	end
	return pityLegendary, pityMythic
end

-- Seconds until each pity timer fires for the player closest to it, from the
-- same last-spawn timestamps GetPityFlags uses. Returns nil, nil when no
-- player is in the server; 0 means that pity is already active. The
-- countdown board shows these values live; nothing here is estimated.
function GameState.GetPityCountdowns()
	local now = os.clock()
	local legendaryRemaining = nil
	local mythicRemaining = nil
	for _, state in pairs(playerStates) do
		local legendaryLeft = BrainrotCatalog.PITY_LEGENDARY_SECONDS - (now - state.lastLegendaryAt)
		local mythicLeft = BrainrotCatalog.PITY_MYTHIC_SECONDS - (now - state.lastMythicAt)
		if legendaryRemaining == nil or legendaryLeft < legendaryRemaining then
			legendaryRemaining = legendaryLeft
		end
		if mythicRemaining == nil or mythicLeft < mythicRemaining then
			mythicRemaining = mythicLeft
		end
	end
	if legendaryRemaining == nil then
		return nil, nil
	end
	return math.max(0, legendaryRemaining), math.max(0, mythicRemaining)
end

function GameState.LoadBaseLayout()
	local basesFolder = Workspace:FindFirstChild("Bases")
	if basesFolder == nil then
		warn("GameState: no Bases folder in the workspace; using catalog centres.")
		for index, centre in ipairs(BrainrotCatalog.BASE_CENTERS) do
			baseCenters[index] = Vector3.new(centre.x, 1, centre.z)
		end
		return
	end
	for index = 1, BrainrotCatalog.BASE_COUNT do
		local base = basesFolder:FindFirstChild("Base" .. tostring(index))
		if base == nil then
			warn("GameState: Base" .. tostring(index) .. " is missing from the workspace.")
		else
			local floor = base:FindFirstChild("Floor")
			if floor ~= nil then
				baseCenters[index] = floor.Position
			end
			local slots = base:FindFirstChild("Slots")
			slotPads[index] = {}
			if slots ~= nil then
				for slot = 1, BrainrotCatalog.SLOTS_PER_BASE do
					slotPads[index][slot] = slots:FindFirstChild("Slot" .. tostring(slot))
				end
			end
			gateParts[index] = base:FindFirstChild("LaserGate")
			signLabels[index] = {}
			local board = base:FindFirstChild("SignBoard")
			if board ~= nil then
				for _, descendant in ipairs(board:GetDescendants()) do
					if descendant:IsA("TextLabel") then
						table.insert(signLabels[index], descendant)
					end
				end
			end
		end
	end
end

function GameState.GetBaseCenter(baseIndex)
	return baseCenters[baseIndex]
end

function GameState.GetSlotPad(baseIndex, slotIndex)
	local pads = slotPads[baseIndex]
	if pads == nil then
		return nil
	end
	return pads[slotIndex]
end

function GameState.GetGatePart(baseIndex)
	return gateParts[baseIndex]
end

function GameState.GetSignLabels(baseIndex)
	return signLabels[baseIndex] or {}
end

function GameState.IsPointInsideBase(point, baseIndex)
	local centre = baseCenters[baseIndex]
	if centre == nil then
		return false
	end
	return math.abs(point.X - centre.X) <= 12 and math.abs(point.Z - centre.Z) <= 12
end

function GameState.GetAllPlayers()
	return Players:GetPlayers()
end

return GameState
