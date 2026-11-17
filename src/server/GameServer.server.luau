-- GameServer: the main server script. It owns the belt, the buying, the
-- base locks, the rebirths and the once-a-second earnings tick, and it wires
-- every remote to the controller that runs it. All validation happens here
-- or in the controllers; the client only ever asks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local SharedFormat = require(ReplicatedStorage:WaitForChild("SharedFormat"))
local GameState = require(script.Parent.GameState)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local StealController = require(script.Parent.StealController)
local TsunamiController = require(script.Parent.TsunamiController)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyBrainrot = Remotes:WaitForChild("BuyBrainrot")
local StealBrainrot = Remotes:WaitForChild("StealBrainrot")
local SlapPlayer = Remotes:WaitForChild("SlapPlayer")
local LockBase = Remotes:WaitForChild("LockBase")
local PerformRebirth = Remotes:WaitForChild("PerformRebirth")
local StateSync = Remotes:WaitForChild("StateSync")
local EventBanner = Remotes:WaitForChild("EventBanner")
local Announce = Remotes:WaitForChild("Announce")

local function getHumanoidRootPart(player)
	local character = player.Character
	if character == nil then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(player)
	local character = player.Character
	if character == nil then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local function announceTo(player, text)
	Announce:FireClient(player, text)
end

local function announceToAll(text)
	for _, player in ipairs(Players:GetPlayers()) do
		Announce:FireClient(player, text)
	end
end

local function updateGateVisual(baseIndex)
	local gate = GameState.GetGatePart(baseIndex)
	if gate == nil then
		return
	end
	local locked = GameState.IsBaseLocked(baseIndex)
	gate.CanCollide = locked
	gate.Transparency = locked and 0.3 or 0.8
	local gui = gate:FindFirstChild("GateGui")
	if gui ~= nil then
		local label = gui:FindFirstChild("GateLabel")
		if label ~= nil then
			label.Text = locked and "LOCKED" or "OPEN"
			label.TextColor3 = locked and Color3.new(1, 0.25, 0.25) or Color3.new(0.4, 1, 0.4)
		end
	end
end

local function setBaseSign(baseIndex, ownerName)
	for _, label in ipairs(GameState.GetSignLabels(baseIndex)) do
		if ownerName ~= nil then
			label.Text = "BASE " .. tostring(baseIndex) .. "\n" .. ownerName
		else
			label.Text = "BASE " .. tostring(baseIndex) .. "\nEMPTY"
		end
	end
end

local function giveRebirthStars(player)
	local character = player.Character
	if character == nil then
		return
	end
	local head = character:FindFirstChild("Head")
	if head == nil then
		return
	end
	for _, child in ipairs(character:GetChildren()) do
		if child.Name == "RebirthStar" then
			child:Destroy()
		end
	end
	local state = GameState.GetState(player)
	local level = 0
	if state ~= nil then
		level = state.rebirthLevel
	end
	for index = 1, level do
		local star = Instance.new("Part")
		star.Name = "RebirthStar"
		star.Shape = Enum.PartType.Ball
		star.Size = Vector3.new(0.8, 0.8, 0.8)
		star.Color = Color3.new(1, 0.85, 0.2)
		star.Material = Enum.Material.Neon
		star.CanCollide = false
		star.Massless = true
		star.CFrame = head.CFrame * CFrame.new((index - (level + 1) / 2) * 1.2, 2.2, 0)
		star.Parent = character
		local weld = Instance.new("Weld")
		weld.Part0 = head
		weld.Part1 = star
		weld.C0 = CFrame.new((index - (level + 1) / 2) * 1.2, 2.2, 0)
		weld.Parent = star
	end
end

local function moveModelTo(model, target, speed, yaw)
	while model.Parent ~= nil do
		local current = model:GetPivot().Position
		local toTarget = target - current
		local distance = toTarget.Magnitude
		if distance < 0.6 then
			model:PivotTo(CFrame.new(target) * CFrame.Angles(0, yaw, 0))
			return true
		end
		local dt = RunService.Heartbeat:Wait()
		local step = math.min(distance, speed * dt)
		local nextPos = current + toTarget.Unit * step
		local bob = math.sin(os.clock() * 6) * 0.15
		model:PivotTo(CFrame.new(nextPos + Vector3.new(0, bob, 0)) * CFrame.Angles(0, yaw, 0))
	end
	return false
end

local function walkBrainrotToSlot(record)
	task.spawn(function()
		local state = GameState.GetState(record.owner)
		if state == nil or state.baseIndex == nil then
			return
		end
		local pad = GameState.GetSlotPad(state.baseIndex, record.slotIndex)
		if pad == nil or record.model == nil then
			return
		end
		local centre = GameState.GetBaseCenter(state.baseIndex)
		local yaw = 0
		if centre ~= nil and centre.Z > 0 then
			yaw = math.pi
		end
		local restHeight = BrainrotFactory.GetModelRestHeight(record.characterId)
		local padTop = pad.Position + Vector3.new(0, 0.2 + restHeight, 0)
		local start = record.model:GetPivot().Position
		local corner = Vector3.new(padTop.X, start.Y, BrainrotCatalog.BELT_Z)
		if moveModelTo(record.model, corner, 10, yaw) then
			if moveModelTo(record.model, padTop, 10, yaw) then
				record.status = "placed"
				local character = BrainrotCatalog.GetCharacter(record.characterId)
				BrainrotFactory.UpdateBrainrotLabel(record.model, character, record.mutation, "placed", record.owner.Name)
				BrainrotFactory.UpdateBrainrotPrompt(record.model, "steal", "STEAL", character.name, true)
			end
		end
	end)
end

local function BuyBrainrotFromBelt(player, uid)
	if type(uid) ~= "string" then
		return
	end
	local record = GameState.FindBrainrotByUid(uid)
	if record == nil or record.status ~= "belt" then
		return
	end
	local root = getHumanoidRootPart(player)
	if root == nil or record.model == nil then
		return
	end
	if (root.Position - record.model:GetPivot().Position).Magnitude > 30 then
		announceTo(player, "Move closer to the belt to buy.")
		return
	end
	local state = GameState.GetState(player)
	if state == nil or state.baseIndex == nil then
		announceTo(player, "No free base right now, so you cannot buy yet.")
		return
	end
	local slotIndex = GameState.FindFreeSlot(player)
	if slotIndex == nil then
		announceTo(player, "Your base is full! Rebirth to start over richer.")
		return
	end
	local character = BrainrotCatalog.GetCharacter(record.characterId)
	if not GameState.SpendCash(player, character.price) then
		announceTo(player, "Not enough cash for " .. character.name .. " (" .. SharedFormat.FormatMoney(character.price) .. ").")
		return
	end
	GameState.RemoveBeltBrainrot(record)
	GameState.GrantBrainrot(player, record, slotIndex)
	record.status = "toBase"
	BrainrotFactory.UpdateBrainrotPrompt(record.model, "walking", "SOLD", character.name, false)
	announceTo(player, "You bought " .. SharedFormat.FormatBrainrotTitle(character, record.mutation) .. "!")
	walkBrainrotToSlot(record)
end

local function SpawnBeltBrainrot()
	if #GameState.GetBeltBrainrots() >= BrainrotCatalog.MAX_BELT_BRAINROTS then
		return
	end
	local pityLegendary, pityMythic = GameState.GetPityFlags()
	local rarityIndex = BrainrotCatalog.RollRarityWithPity(pityLegendary, pityMythic)
	local character = BrainrotCatalog.GetRandomCharacterOfRarity(rarityIndex)
	local mutationName = BrainrotCatalog.RollMutation()
	local uid = GameState.NextUid()
	local restHeight = BrainrotFactory.GetModelRestHeight(character.id)
	local spawnCFrame = CFrame.new(BrainrotCatalog.BELT_START_X, BrainrotCatalog.BELT_TOP_Y + restHeight, BrainrotCatalog.BELT_Z)
		* CFrame.Angles(0, math.rad(90), 0)
	local model = BrainrotFactory.BuildBrainrotModel(character.id, mutationName, uid, spawnCFrame)
	model.Parent = game:GetService("Workspace")
	local record = {
		uid = uid,
		characterId = character.id,
		mutation = mutationName,
		model = model,
		status = "belt",
		x = BrainrotCatalog.BELT_START_X,
		phase = math.random() * 6.28,
	}
	GameState.RegisterBeltBrainrot(record)
	GameState.NoteRaritySpawned(rarityIndex)
	if rarityIndex >= 4 then
		EventBanner:FireAllClients({
			kind = "rareAlert",
			text = SharedFormat.FormatRarityTag(rarityIndex) .. " ON THE BELT: " .. character.name .. "!",
			seconds = 5,
		})
	end
end

local function findNextTier(player)
	local ownedCounts = GameState.GetOwnedCountsByCharacter(player)
	for _, character in ipairs(BrainrotCatalog.CHARACTERS) do
		if (ownedCounts[character.id] or 0) == 0 then
			return character
		end
	end
	return nil
end

local function pushStateToPlayer(player)
	local state = GameState.GetState(player)
	if state == nil then
		return
	end
	local nextTier = findNextTier(player)
	local snapshot = {
		cash = state.cash,
		income = GameState.GetIncomePerSecond(player),
		lockRemaining = GameState.GetLockRemaining(player),
		rebirthLevel = state.rebirthLevel,
		multiplier = state.multiplier,
		ownedCount = GameState.GetOwnedCount(player),
		slotsUsed = GameState.GetOwnedCount(player),
		baseIndex = state.baseIndex,
		carrying = StealController.GetCarriedBrainrot(player) ~= nil,
		ownedCounts = GameState.GetOwnedCountsByCharacter(player),
		nextTierName = nextTier ~= nil and nextTier.name or nil,
		nextTierPrice = nextTier ~= nil and nextTier.price or nil,
	}
	StateSync:FireClient(player, snapshot)
end

-- Spawns the player in front of their own base gate, facing the belt, so a
-- fresh spawn never starts with the long walk across empty grass from the
-- spawn platform. Runs on every CharacterAdded (join and respawn). When the
-- player has no base (all 8 taken) or the layout is missing, it does nothing
-- and the default SpawnLocation behaviour is kept.
local function teleportCharacterToOwnBase(player, character, humanoid)
	local state = GameState.GetState(player)
	if state == nil or state.baseIndex == nil then
		return
	end
	local gate = GameState.GetGatePart(state.baseIndex)
	local centre = GameState.GetBaseCenter(state.baseIndex)
	if gate == nil or centre == nil then
		return
	end
	local rootPart = character:WaitForChild("HumanoidRootPart")
	-- Bases sit on both sides of the belt, so the belt side is the direction
	-- from the gate toward BELT_Z, and the spawn point sits 7 studs outside
	-- the gate on that side, centred on the gate.
	local beltDirection = 1
	if gate.Position.Z > BrainrotCatalog.BELT_Z then
		beltDirection = -1
	end
	-- The spawn point is on the grass outside the gate: the grass top sits
	-- half the floor's thickness below the floor centre, and the root part
	-- rides HipHeight plus half its own height above the ground, so the feet
	-- rest exactly on the grass for any rig.
	local groundY = centre.Y - 0.5
	local rootY = groundY + humanoid.HipHeight + rootPart.Size.Y / 2
	local spawnPosition = Vector3.new(gate.Position.X, rootY, gate.Position.Z + beltDirection * 7)
	-- CFrame yaw 0 faces -Z and math.pi faces +Z: face the belt.
	local yaw = beltDirection > 0 and math.pi or 0
	character:PivotTo(CFrame.new(spawnPosition) * CFrame.Angles(0, yaw, 0))
end

local function onPlayerAdded(player)
	local baseIndex = GameState.AssignBase(player)
	if baseIndex ~= nil then
		setBaseSign(baseIndex, player.Name)
		updateGateVisual(baseIndex)
	end
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = GameState.GetWalkSpeedFor(player)
		teleportCharacterToOwnBase(player, character, humanoid)
		giveRebirthStars(player)
		humanoid.Died:Connect(function()
			StealController.HandleCarrierLeaving(player)
		end)
	end)
	pushStateToPlayer(player)
end

local function onPlayerRemoving(player)
	StealController.HandleCarrierLeaving(player)
	local state = GameState.GetState(player)
	if state ~= nil then
		for _, record in pairs(state.owned) do
			if record.model ~= nil then
				record.model:Destroy()
			end
		end
		if state.baseIndex ~= nil then
			setBaseSign(state.baseIndex, nil)
		end
	end
	GameState.RemovePlayer(player)
	if state ~= nil and state.baseIndex ~= nil then
		updateGateVisual(state.baseIndex)
	end
end

BuyBrainrot.OnServerEvent:Connect(function(player, uid)
	BuyBrainrotFromBelt(player, uid)
	pushStateToPlayer(player)
end)

StealBrainrot.OnServerEvent:Connect(function(player, uid)
	if type(uid) ~= "string" then
		return
	end
	local record = GameState.FindBrainrotByUid(uid)
	local ok, message = StealController.StealBrainrotFromBase(player, record)
	if not ok and message ~= nil then
		announceTo(player, message)
	end
end)

SlapPlayer.OnServerEvent:Connect(function(player)
	StealController.SlapPlayer(player)
end)

LockBase.OnServerEvent:Connect(function(player)
	local state = GameState.GetState(player)
	if state == nil or state.baseIndex == nil then
		announceTo(player, "You have no base to lock.")
		return
	end
	if GameState.GetLockRemaining(player) > 0 then
		announceTo(player, "Your base is already locked.")
		return
	end
	local seconds = GameState.GetLockSecondsFor(player)
	GameState.SetBaseLock(player, seconds)
	updateGateVisual(state.baseIndex)
	announceTo(player, "Base locked for " .. tostring(seconds) .. " seconds!")
	local baseIndex = state.baseIndex
	task.delay(seconds + 0.5, function()
		updateGateVisual(baseIndex)
	end)
	pushStateToPlayer(player)
end)

PerformRebirth.OnServerEvent:Connect(function(player)
	local ok, message = GameState.PerformRebirth(player)
	if ok then
		local humanoid = getHumanoid(player)
		if humanoid ~= nil then
			humanoid.WalkSpeed = GameState.GetWalkSpeedFor(player)
		end
		giveRebirthStars(player)
		local state = GameState.GetState(player)
		announceToAll(player.Name .. " REBIRTHED! Now earning x" .. tostring(state.multiplier) .. "!")
	else
		announceTo(player, message)
	end
	pushStateToPlayer(player)
end)

GameState.LoadBaseLayout()

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

RunService.Heartbeat:Connect(function(dt)
	local belt = GameState.GetBeltBrainrots()
	for index = #belt, 1, -1 do
		local record = belt[index]
		if record.status ~= "belt" or record.model == nil or record.model.Parent == nil then
			table.remove(belt, index)
		else
			record.x = record.x + BrainrotCatalog.BELT_SPEED * dt
			if record.x > BrainrotCatalog.BELT_END_X then
				record.model:Destroy()
				table.remove(belt, index)
			else
				local character = BrainrotCatalog.GetCharacter(record.characterId)
				local restHeight = BrainrotFactory.GetModelRestHeight(character.id)
				local bob = math.sin(os.clock() * 3 + record.phase) * 0.15
				record.model:PivotTo(
					CFrame.new(record.x, BrainrotCatalog.BELT_TOP_Y + restHeight + bob, BrainrotCatalog.BELT_Z)
						* CFrame.Angles(0, math.rad(90), 0)
				)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(BrainrotCatalog.BELT_SPAWN_SECONDS)
		SpawnBeltBrainrot()
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		GameState.TickEarnings(1)
		for _, player in ipairs(Players:GetPlayers()) do
			pushStateToPlayer(player)
		end
	end
end)

TsunamiController.StartTsunamiLoop()
