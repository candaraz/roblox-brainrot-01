-- StealController: the whole stealing game. A player grabs a brainrot from an
-- unlocked rival base, is slowed while carrying it, and must reach their own
-- base to keep it. A slap from anyone nearby returns the brainrot to its
-- owner and stuns the carrier. The server owns every step; the client only
-- asks through the remotes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local SharedFormat = require(ReplicatedStorage:WaitForChild("SharedFormat"))
local GameState = require(script.Parent.GameState)
local BrainrotFactory = require(script.Parent.BrainrotFactory)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Announce = Remotes:WaitForChild("Announce")

local StealController = {}

local carryLoops = {}
local carriedRecords = {}

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

local function restoreWalkSpeed(player)
	local state = GameState.GetState(player)
	local humanoid = getHumanoid(player)
	if state ~= nil and humanoid ~= nil then
		humanoid.WalkSpeed = GameState.GetWalkSpeedFor(player)
	end
end

local function stunPlayer(player, seconds)
	local humanoid = getHumanoid(player)
	if humanoid == nil then
		return
	end
	humanoid.WalkSpeed = 0
	task.delay(seconds, function()
		if player.Parent == Players then
			restoreWalkSpeed(player)
		end
	end)
end

function StealController.StealBrainrotFromBase(thief, record)
	if record == nil or record.status ~= "placed" then
		return false, "That brainrot is not on a base."
	end
	if record.owner == thief then
		return false, "That brainrot is already yours."
	end
	if record.owner == nil or record.baseIndex == nil then
		return false, "That brainrot has no home base."
	end
	if GameState.IsBaseLocked(record.baseIndex) then
		return false, "That base is locked."
	end
	local thiefState = GameState.GetState(thief)
	if thiefState == nil or thiefState.baseIndex == nil then
		return false, "You need a base before you can steal."
	end
	if StealController.GetCarriedBrainrot(thief) ~= nil then
		return false, "You are already carrying a brainrot."
	end
	local root = getHumanoidRootPart(thief)
	if root == nil or record.model == nil then
		return false, "Move closer to steal."
	end
	if (root.Position - record.model:GetPivot().Position).Magnitude > 25 then
		return false, "Move closer to steal."
	end
	local owner = record.owner
	local homeBase = record.baseIndex
	local homeSlot = record.slotIndex
	GameState.ReleaseBrainrot(record)
	record.status = "carried"
	record.carrier = thief
	record.homeOwner = owner
	record.homeBase = homeBase
	record.homeSlot = homeSlot
	carriedRecords[thief] = record
	local character = BrainrotCatalog.GetCharacter(record.characterId)
	BrainrotFactory.UpdateBrainrotLabel(record.model, character, record.mutation, "carried", nil)
	BrainrotFactory.UpdateBrainrotPrompt(record.model, "carried", "STOLEN", character.name, false)
	local humanoid = getHumanoid(thief)
	if humanoid ~= nil then
		humanoid.WalkSpeed = GameState.GetWalkSpeedFor(thief) * BrainrotCatalog.STEAL_SLOW
	end
	announceTo(thief, "You stole " .. character.name .. "! Run home!")
	if owner ~= nil and owner.Parent == Players then
		announceTo(owner, thief.Name .. " is stealing your " .. character.name .. "! Slap them!")
	end
	StealController.StartCarryFollowLoop(record)
	return true, "Stolen!"
end

function StealController.StartCarryFollowLoop(record)
	local uid = record.uid
	if carryLoops[uid] ~= nil then
		return
	end
	carryLoops[uid] = true
	task.spawn(function()
		while record.status == "carried" and record.model ~= nil and record.model.Parent ~= nil do
			local carrier = record.carrier
			local root = nil
			if carrier ~= nil then
				root = getHumanoidRootPart(carrier)
			end
			if root == nil then
				StealController.ReturnStolenBrainrot(record, "The carrier left.")
				break
			end
			record.model:PivotTo(CFrame.new(root.Position + Vector3.new(0, 4.5, 0)))
			local carrierState = GameState.GetState(carrier)
			if carrierState ~= nil and carrierState.baseIndex ~= nil then
				if GameState.IsPointInsideBase(root.Position, carrierState.baseIndex) then
					StealController.DeliverStolenBrainrot(record)
					break
				end
			end
			RunService.Heartbeat:Wait()
		end
		carryLoops[uid] = nil
	end)
end

function StealController.DeliverStolenBrainrot(record)
	local carrier = record.carrier
	if carrier == nil then
		StealController.ReturnStolenBrainrot(record, "No carrier.")
		return false
	end
	carriedRecords[carrier] = nil
	local slotIndex = GameState.FindFreeSlot(carrier)
	if slotIndex == nil then
		StealController.ReturnStolenBrainrot(record, "Your base is full.")
		if carrier.Parent == Players then
			announceTo(carrier, "Your base is full! The brainrot ran home.")
		end
		return false
	end
	local state = GameState.GetState(carrier)
	GameState.GrantBrainrot(carrier, record, slotIndex)
	record.status = "placed"
	record.carrier = nil
	record.homeOwner = nil
	restoreWalkSpeed(carrier)
	local character = BrainrotCatalog.GetCharacter(record.characterId)
	BrainrotFactory.UpdateBrainrotLabel(record.model, character, record.mutation, "placed", carrier.Name)
	BrainrotFactory.UpdateBrainrotPrompt(record.model, "steal", "STEAL", character.name, true)
	local pad = GameState.GetSlotPad(state.baseIndex, slotIndex)
	if pad ~= nil then
		local restHeight = BrainrotFactory.GetModelRestHeight(record.characterId)
		record.model:PivotTo(CFrame.new(pad.Position + Vector3.new(0, restHeight, 0)))
	end
	announceTo(carrier, "Delivered! " .. character.name .. " now earns for you.")
	return true
end

function StealController.ReturnStolenBrainrot(record, reason)
	local homeOwner = record.homeOwner
	local homeBase = record.homeBase
	local homeSlot = record.homeSlot
	local carrier = record.carrier
	record.status = "returning"
	record.carrier = nil
	if carrier ~= nil then
		carriedRecords[carrier] = nil
	end
	if carrier ~= nil and carrier.Parent == Players then
		restoreWalkSpeed(carrier)
	end
	if homeOwner ~= nil and homeOwner.Parent == Players and homeBase ~= nil and homeSlot ~= nil then
		local homeState = GameState.GetState(homeOwner)
		if homeState ~= nil then
			GameState.GrantBrainrot(homeOwner, record, homeSlot)
			record.status = "placed"
			local character = BrainrotCatalog.GetCharacter(record.characterId)
			BrainrotFactory.UpdateBrainrotLabel(record.model, character, record.mutation, "placed", homeOwner.Name)
			BrainrotFactory.UpdateBrainrotPrompt(record.model, "steal", "STEAL", character.name, true)
			local pad = GameState.GetSlotPad(homeBase, homeSlot)
			if pad ~= nil then
				local restHeight = BrainrotFactory.GetModelRestHeight(record.characterId)
				record.model:PivotTo(CFrame.new(pad.Position + Vector3.new(0, restHeight, 0)))
			end
			announceTo(homeOwner, character.name .. " is safe at home. (" .. reason .. ")")
			return true
		end
	end
	if record.model ~= nil then
		record.model:Destroy()
	end
	record.model = nil
	record.status = "gone"
	return false
end

function StealController.GetCarriedBrainrot(player)
	return carriedRecords[player]
end

function StealController.SlapPlayer(slapper)
	local state = GameState.GetState(slapper)
	if state == nil then
		return false
	end
	local now = os.clock()
	if now < state.slapReadyAt then
		return false
	end
	state.slapReadyAt = now + BrainrotCatalog.SLAP_COOLDOWN
	local slapperRoot = getHumanoidRootPart(slapper)
	if slapperRoot == nil then
		return false
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= slapper then
			local carried = StealController.GetCarriedBrainrot(other)
			if carried ~= nil then
				local otherRoot = getHumanoidRootPart(other)
				if otherRoot ~= nil and (otherRoot.Position - slapperRoot.Position).Magnitude <= BrainrotCatalog.SLAP_RANGE then
					local character = BrainrotCatalog.GetCharacter(carried.characterId)
					local away = otherRoot.Position - slapperRoot.Position
					if away.Magnitude < 0.1 then
						away = Vector3.new(1, 0, 0)
					end
					otherRoot.AssemblyLinearVelocity = away.Unit * 30 + Vector3.new(0, 25, 0)
					stunPlayer(other, 2)
					StealController.ReturnStolenBrainrot(carried, "Slapped by " .. slapper.Name .. "!")
					announceTo(slapper, "SLAP! You saved " .. character.name .. ".")
					return true
				end
			end
		end
	end
	return false
end

function StealController.HandleCarrierLeaving(player)
	local carried = StealController.GetCarriedBrainrot(player)
	if carried ~= nil then
		StealController.ReturnStolenBrainrot(carried, "The carrier left.")
	end
end

function StealController.FormatCarryWarning(record)
	local character = BrainrotCatalog.GetCharacter(record.characterId)
	return "Carrying " .. SharedFormat.FormatBrainrotTitle(character, record.mutation) .. " - get home!"
end

return StealController
