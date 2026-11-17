-- BrainrotHud: the whole in-game interface. Money, income, the next tier to
-- buy, the lock and rebirth buttons, the event banner and the toasts. Every
-- panel sits clear of the top-left corner, where Roblox's own menu buttons
-- sit, and every number is big enough to read on a screenshot scaled down.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local SharedFormat = require(ReplicatedStorage:WaitForChild("SharedFormat"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BuyBrainrot = Remotes:WaitForChild("BuyBrainrot")
local StealBrainrot = Remotes:WaitForChild("StealBrainrot")
local SlapPlayer = Remotes:WaitForChild("SlapPlayer")
local LockBase = Remotes:WaitForChild("LockBase")
local PerformRebirth = Remotes:WaitForChild("PerformRebirth")
local StateSync = Remotes:WaitForChild("StateSync")
local EventBanner = Remotes:WaitForChild("EventBanner")
local Announce = Remotes:WaitForChild("Announce")

local player = Players.LocalPlayer

local moneyLabel
local rateLabel
local rebirthBadge
local baseLabel
local nextTierLabel
local lockButton
local rebirthButton
local bannerFrame
local bannerLabel
local toastLabel
local carryLabel

local bannerToken = 0
local connectedPrompts = {}

local function makePanel(parent, name, anchor, position, size)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.AnchorPoint = anchor
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = Color3.new(0.08, 0.1, 0.2)
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.5
	stroke.Parent = frame
	frame.Parent = parent
	return frame
end

local function makeLabel(parent, name, position, size, textSize, colour)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = ""
	label.TextColor3 = colour
	label.TextScaled = false
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
	label.Parent = parent
	return label
end

local function makeButton(parent, name, anchor, position, size, text, textSize, colour)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = anchor
	button.Position = position
	button.Size = size
	button.BackgroundColor3 = colour
	button.BackgroundTransparency = 0.1
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = textSize
	button.TextWrapped = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Transparency = 0.4
	stroke.Parent = button
	button.Parent = parent
	return button
end

local function BuildBrainrotHud()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BrainrotHud"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10

	local moneyPanel = makePanel(gui, "MoneyPanel", Vector2.new(1, 0), UDim2.new(1, -16, 0, 16), UDim2.new(0, 320, 0, 130))
	moneyLabel = makeLabel(moneyPanel, "MoneyLabel", UDim2.new(0, 0, 0, 4), UDim2.new(1, 0, 0, 52), 44, Color3.new(1, 0.9, 0.3))
	rateLabel = makeLabel(moneyPanel, "RateLabel", UDim2.new(0, 0, 0, 56), UDim2.new(1, 0, 0, 34), 28, Color3.new(0.4, 1, 0.4))
	rebirthBadge = makeLabel(moneyPanel, "RebirthBadge", UDim2.new(0, 0, 0, 90), UDim2.new(1, 0, 0, 30), 22, Color3.new(1, 0.7, 0.9))

	local nextPanel = makePanel(gui, "NextTierPanel", Vector2.new(1, 0), UDim2.new(1, -16, 0, 156), UDim2.new(0, 320, 0, 64))
	nextTierLabel = makeLabel(nextPanel, "NextTierLabel", UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 1, -8), 24, Color3.new(1, 1, 1))
	nextTierLabel.TextXAlignment = Enum.TextXAlignment.Center
	nextTierLabel.TextWrapped = true

	baseLabel = makeLabel(gui, "BaseLabel", UDim2.new(1, -336, 0, 230), UDim2.new(0, 320, 0, 30), 22, Color3.new(1, 1, 1))
	baseLabel.AnchorPoint = Vector2.new(1, 0)

	bannerFrame = makePanel(gui, "EventBanner", Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 16), UDim2.new(0, 620, 0, 70))
	bannerFrame.BackgroundColor3 = Color3.new(0.85, 0.15, 0.15)
	bannerFrame.BackgroundTransparency = 0.1
	bannerFrame.Visible = false
	bannerLabel = makeLabel(bannerFrame, "BannerLabel", UDim2.new(0, 8, 0, 4), UDim2.new(1, -16, 1, -8), 32, Color3.new(1, 1, 1))
	bannerLabel.TextWrapped = true

	carryLabel = makeLabel(gui, "CarryLabel", UDim2.new(0.5, 0, 0, 96), UDim2.new(0, 560, 0, 44), 30, Color3.new(1, 0.6, 0.2))
	carryLabel.AnchorPoint = Vector2.new(0.5, 0)
	carryLabel.Visible = false

	lockButton = makeButton(
		gui,
		"LockButton",
		Vector2.new(1, 1),
		UDim2.new(1, -16, 1, -16),
		UDim2.new(0, 240, 0, 68),
		"LOCK BASE (L)",
		26,
		Color3.new(0.85, 0.2, 0.2)
	)
	rebirthButton = makeButton(
		gui,
		"RebirthButton",
		Vector2.new(1, 1),
		UDim2.new(1, -16, 1, -96),
		UDim2.new(0, 280, 0, 68),
		"REBIRTH (R)",
		24,
		Color3.new(0.6, 0.3, 0.95)
	)
	local slapButton = makeButton(
		gui,
		"SlapButton",
		Vector2.new(1, 1),
		UDim2.new(1, -16, 1, -176),
		UDim2.new(0, 200, 0, 60),
		"SLAP (Q)",
		26,
		Color3.new(0.2, 0.55, 1)
	)

	toastLabel = makeLabel(gui, "ToastLabel", UDim2.new(0.5, 0, 1, -120), UDim2.new(0, 640, 0, 44), 28, Color3.new(1, 1, 1))
	toastLabel.AnchorPoint = Vector2.new(0.5, 1)
	toastLabel.Visible = false

	local helpLabel = makeLabel(gui, "HelpLabel", UDim2.new(0, 16, 1, -44), UDim2.new(0, 560, 0, 28), 20, Color3.new(1, 1, 1))
	helpLabel.AnchorPoint = Vector2.new(0, 1)
	helpLabel.TextXAlignment = Enum.TextXAlignment.Left
	helpLabel.Text = "E buy / steal  -  Q slap  -  L lock base  -  R rebirth  -  C cast list"

	lockButton.MouseButton1Click:Connect(function()
		LockBase:FireServer()
	end)
	rebirthButton.MouseButton1Click:Connect(function()
		PerformRebirth:FireServer()
	end)
	slapButton.MouseButton1Click:Connect(function()
		SlapPlayer:FireServer()
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

local function ShowToast(text)
	toastLabel.Text = text
	toastLabel.Visible = true
	toastLabel.TextTransparency = 0
	task.delay(2.5, function()
		local tween = TweenService:Create(toastLabel, TweenInfo.new(0.5), { TextTransparency = 1 })
		tween:Play()
		tween.Completed:Connect(function()
			toastLabel.Visible = false
		end)
	end)
end

local function ShowEventBanner(payload)
	bannerToken = bannerToken + 1
	local token = bannerToken
	local seconds = payload.seconds or 5
	bannerFrame.Visible = true
	if payload.kind == "tsunamiWarn" then
		local remaining = seconds
		while remaining > 0 and token == bannerToken do
			bannerLabel.Text = payload.text .. " " .. tostring(remaining) .. "s"
			task.wait(1)
			remaining = remaining - 1
		end
	else
		bannerLabel.Text = payload.text
		task.wait(seconds)
	end
	if token == bannerToken then
		bannerFrame.Visible = false
	end
end

local function UpdateHudFromState(snapshot)
	moneyLabel.Text = SharedFormat.FormatMoney(snapshot.cash)
	rateLabel.Text = "+" .. SharedFormat.FormatMoneyPerSecond(snapshot.income)
	if snapshot.rebirthLevel > 0 then
		rebirthBadge.Text = "REBIRTH " .. tostring(snapshot.rebirthLevel) .. "  -  x" .. tostring(snapshot.multiplier) .. " INCOME"
	else
		rebirthBadge.Text = "NO REBIRTH YET"
	end
	if snapshot.baseIndex ~= nil then
		baseLabel.Text = "BASE " .. tostring(snapshot.baseIndex) .. "  -  " .. tostring(snapshot.ownedCount) .. "/"
			.. tostring(BrainrotCatalog.SLOTS_PER_BASE) .. " BRAINROTS"
	else
		baseLabel.Text = "NO BASE - SPECTATING"
	end
	if snapshot.nextTierName ~= nil then
		nextTierLabel.Text = "NEXT: " .. snapshot.nextTierName .. " - " .. SharedFormat.FormatMoney(snapshot.nextTierPrice)
	else
		nextTierLabel.Text = "CAST COMPLETE! YOU OWN THEM ALL!"
	end
	if snapshot.lockRemaining > 0 then
		lockButton.Text = "LOCKED " .. SharedFormat.FormatCountdown(snapshot.lockRemaining)
		lockButton.BackgroundColor3 = Color3.new(0.4, 0.4, 0.45)
	else
		lockButton.Text = "LOCK BASE (L)"
		lockButton.BackgroundColor3 = Color3.new(0.85, 0.2, 0.2)
	end
	local requirement = BrainrotCatalog.GetRebirthRequirement(snapshot.rebirthLevel)
	if requirement == nil then
		rebirthButton.Text = "MAX REBIRTH!"
	else
		rebirthButton.Text = "REBIRTH (R): " .. SharedFormat.FormatMoney(requirement.cash) .. " + "
			.. BrainrotCatalog.GetRarityName(requirement.needRarity) .. "+"
	end
	carryLabel.Visible = snapshot.carrying
	if snapshot.carrying then
		carryLabel.Text = "YOU ARE CARRYING A STOLEN BRAINROT - RUN HOME!"
	end
end

local function connectPrompt(prompt)
	if connectedPrompts[prompt] then
		return
	end
	connectedPrompts[prompt] = true
	prompt.Triggered:Connect(function()
		local kind = prompt:GetAttribute("Kind")
		local uid = prompt:GetAttribute("Uid")
		if uid == nil then
			return
		end
		if kind == "buy" then
			BuyBrainrot:FireServer(uid)
		elseif kind == "steal" then
			StealBrainrot:FireServer(uid)
		end
	end)
end

local function scanPrompts()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			connectPrompt(descendant)
		end
	end
end

local function bindActionKeys()
	ContextActionService:BindAction("BrainrotSlap", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			SlapPlayer:FireServer()
		end
	end, false, Enum.KeyCode.Q)
	ContextActionService:BindAction("BrainrotLock", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			LockBase:FireServer()
		end
	end, false, Enum.KeyCode.L)
	ContextActionService:BindAction("BrainrotRebirth", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			PerformRebirth:FireServer()
		end
	end, false, Enum.KeyCode.R)
end

BuildBrainrotHud()
scanPrompts()
Workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("ProximityPrompt") then
		connectPrompt(descendant)
	end
end)
bindActionKeys()

StateSync.OnClientEvent:Connect(UpdateHudFromState)
EventBanner.OnClientEvent:Connect(function(payload)
	task.spawn(ShowEventBanner, payload)
end)
Announce.OnClientEvent:Connect(ShowToast)
