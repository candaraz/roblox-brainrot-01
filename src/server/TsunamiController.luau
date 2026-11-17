-- TsunamiController: the wave event. Every few minutes a warning banner tells
-- every player to dash home, then a wall of water sweeps the whole map.
-- Players caught outside their own base are knocked back and stunned. The
-- wave threatens the dash home; it never takes a brainrot away.
-- TOUR.json calls TriggerTsunamiWave so reviewers can stage the event shot.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local GameState = require(script.Parent.GameState)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EventBanner = Remotes:WaitForChild("EventBanner")
local Announce = Remotes:WaitForChild("Announce")

local TsunamiController = {}

local waveRunning = false
local lastHitAt = {}
-- The os.clock() moment the loop's next scheduled wave fires. The countdown
-- board above the belt reads it; nil until the loop starts, which the getter
-- reports as the full first-wave delay.
local nextWaveAt = nil

local function getHumanoidRootPart(player)
	local character = player.Character
	if character == nil then
		return nil
	end
	return character:FindFirstChild("HumanoidRootPart")
end

local function knockPlayerBack(player, wallX)
	local root = getHumanoidRootPart(player)
	if root == nil then
		return
	end
	root.AssemblyLinearVelocity = Vector3.new(BrainrotCatalog.TSUNAMI_SPEED * 1.2, 30, 0)
	local character = player.Character
	local humanoid = nil
	if character ~= nil then
		humanoid = character:FindFirstChildOfClass("Humanoid")
	end
	if humanoid ~= nil then
		humanoid.WalkSpeed = 0
		task.delay(2, function()
			if player.Parent == Players then
				local stillThere = player.Character
				local fresh = nil
				if stillThere ~= nil then
					fresh = stillThere:FindFirstChildOfClass("Humanoid")
				end
				if fresh ~= nil then
					fresh.WalkSpeed = GameState.GetWalkSpeedFor(player)
				end
			end
		end)
	end
	Announce:FireClient(player, "The wave caught you! Dash home next time!")
end

local function isPlayerSafeFromWave(player)
	local state = GameState.GetState(player)
	local root = getHumanoidRootPart(player)
	if state == nil or root == nil or state.baseIndex == nil then
		return true
	end
	return GameState.IsPointInsideBase(root.Position, state.baseIndex)
end

local function buildTsunamiWall()
	local model = Instance.new("Model")
	model.Name = "TsunamiWave"
	local body = Instance.new("Part")
	body.Name = "WaveBody"
	body.Size = Vector3.new(6, 30, 520)
	body.Color = Color3.new(0.2, 0.5, 1)
	body.Material = Enum.Material.SmoothPlastic
	body.Transparency = 0.35
	body.Anchored = true
	body.CanCollide = false
	body.CanQuery = false
	body.CanTouch = false
	body.CFrame = CFrame.new(-170, 15, 0)
	body.Parent = model
	local crest = Instance.new("Part")
	crest.Name = "WaveCrest"
	crest.Size = Vector3.new(8, 4, 520)
	crest.Color = Color3.new(0.9, 0.97, 1)
	crest.Material = Enum.Material.Neon
	crest.Anchored = true
	crest.CanCollide = false
	crest.CanQuery = false
	crest.CanTouch = false
	crest.CFrame = CFrame.new(-170, 31, 0)
	crest.Parent = model
	model.PrimaryPart = body
	model.Parent = Workspace
	return model
end

function TsunamiController.TriggerTsunamiWave()
	if waveRunning then
		return false
	end
	waveRunning = true
	EventBanner:FireAllClients({
		kind = "tsunamiWarn",
		text = "TSUNAMI INCOMING! GET TO YOUR BASE!",
		seconds = BrainrotCatalog.TSUNAMI_WARN_SECONDS,
	})
	task.wait(BrainrotCatalog.TSUNAMI_WARN_SECONDS)
	EventBanner:FireAllClients({
		kind = "tsunamiNow",
		text = "THE WAVE IS HERE!",
		seconds = 8,
	})
	local wall = buildTsunamiWall()
	local wallX = -170
	local hitCooldown = {}
	while wallX < 170 do
		local dt = RunService.Heartbeat:Wait()
		wallX = wallX + BrainrotCatalog.TSUNAMI_SPEED * dt
		wall:PivotTo(CFrame.new(wallX, 15, 0))
		for _, player in ipairs(Players:GetPlayers()) do
			local root = getHumanoidRootPart(player)
			if root ~= nil and math.abs(root.Position.X - wallX) < 8 then
				local now = os.clock()
				if (hitCooldown[player] or 0) < now and not isPlayerSafeFromWave(player) then
					hitCooldown[player] = now + 3
					lastHitAt[player] = now
					knockPlayerBack(player, wallX)
				end
			end
		end
	end
	wall:Destroy()
	waveRunning = false
	return true
end

function TsunamiController.StartTsunamiLoop()
	task.spawn(function()
		nextWaveAt = os.clock() + BrainrotCatalog.TSUNAMI_FIRST_SECONDS
		task.wait(BrainrotCatalog.TSUNAMI_FIRST_SECONDS)
		while true do
			TsunamiController.TriggerTsunamiWave()
			nextWaveAt = os.clock() + BrainrotCatalog.TSUNAMI_EVERY_SECONDS
			task.wait(BrainrotCatalog.TSUNAMI_EVERY_SECONDS)
		end
	end)
end

-- Seconds until the loop's next scheduled wave. During a wave this keeps
-- counting toward the following one; callers show the wave state instead
-- while IsWaveRunning() is true.
function TsunamiController.GetSecondsUntilNextWave()
	if nextWaveAt == nil then
		return BrainrotCatalog.TSUNAMI_FIRST_SECONDS
	end
	return math.max(0, nextWaveAt - os.clock())
end

function TsunamiController.IsWaveRunning()
	return waveRunning
end

function TsunamiController.GetLastHitAt(player)
	return lastHitAt[player]
end

return TsunamiController
