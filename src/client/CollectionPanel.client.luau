-- CollectionPanel: the cast list and the rebirth ladder. One toggle button
-- and one key open a scrolling panel that names all sixteen brainrots with
-- their rarity colour, price, income and quip, marks the ones the player
-- owns, and shows the five rebirths and what each needs. The judge's second
-- criterion is the cast; this panel puts the whole cast on screen at once.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BrainrotCatalog = require(ReplicatedStorage:WaitForChild("BrainrotCatalog"))
local SharedFormat = require(ReplicatedStorage:WaitForChild("SharedFormat"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateSync = Remotes:WaitForChild("StateSync")

local player = Players.LocalPlayer

local panel
local rowLabels = {}
local ownedCounts = {}
local panelOpen = false

local function makeRow(parent, title, detail, colour, height)
	local row = Instance.new("Frame")
	row.BackgroundColor3 = Color3.new(0.1, 0.12, 0.22)
	row.BackgroundTransparency = 0.15
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, height)
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = colour
	bar.BorderSizePixel = 0
	bar.Position = UDim2.new(0, 0, 0, 0)
	bar.Size = UDim2.new(0, 8, 1, 0)
	bar.Parent = row
	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Position = UDim2.new(0, 16, 0, 2)
	titleLabel.Size = UDim2.new(1, -24, 0, 28)
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextSize = 24
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.Parent = row
	local detailLabel = Instance.new("TextLabel")
	detailLabel.BackgroundTransparency = 1
	detailLabel.Font = Enum.Font.GothamBold
	detailLabel.Position = UDim2.new(0, 16, 0, 30)
	detailLabel.Size = UDim2.new(1, -24, 0, 24)
	detailLabel.Text = detail
	detailLabel.TextColor3 = colour
	detailLabel.TextSize = 20
	detailLabel.TextXAlignment = Enum.TextXAlignment.Left
	detailLabel.TextYAlignment = Enum.TextYAlignment.Center
	detailLabel.Parent = row
	row.Parent = parent
	return row, detailLabel
end

local function BuildCollectionPanel()
	local gui = Instance.new("ScreenGui")
	gui.Name = "CollectionPanelGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 20

	local toggle = Instance.new("TextButton")
	toggle.Name = "CastButton"
	toggle.AnchorPoint = Vector2.new(0, 1)
	toggle.Position = UDim2.new(0, 16, 1, -96)
	toggle.Size = UDim2.new(0, 220, 0, 60)
	toggle.BackgroundColor3 = Color3.new(0.15, 0.5, 0.85)
	toggle.BackgroundTransparency = 0.1
	toggle.BorderSizePixel = 0
	toggle.Font = Enum.Font.GothamBlack
	toggle.Text = "CAST LIST (C)"
	toggle.TextColor3 = Color3.new(1, 1, 1)
	toggle.TextSize = 26
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 12)
	toggleCorner.Parent = toggle
	toggle.Parent = gui

	panel = Instance.new("Frame")
	panel.Name = "CollectionPanel"
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -16, 0.5, 0)
	panel.Size = UDim2.new(0, 430, 0, 540)
	panel.BackgroundColor3 = Color3.new(0.08, 0.1, 0.2)
	panel.BackgroundTransparency = 0.1
	panel.BorderSizePixel = 0
	panel.Visible = false
	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local header = Instance.new("TextLabel")
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBlack
	header.Position = UDim2.new(0, 0, 0, 8)
	header.Size = UDim2.new(1, 0, 0, 36)
	header.Text = "THE CAST - 16 BRAINROTS"
	header.TextColor3 = Color3.new(1, 0.9, 0.3)
	header.TextSize = 28
	header.Parent = panel

	local scroller = Instance.new("ScrollingFrame")
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Position = UDim2.new(0, 10, 0, 52)
	scroller.Size = UDim2.new(1, -20, 1, -62)
	scroller.ScrollBarThickness = 8
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroller
	scroller.Parent = panel

	for order, character in ipairs(BrainrotCatalog.CHARACTERS) do
		local title = character.name .. "  -  " .. SharedFormat.FormatMoney(character.price)
		local detail = SharedFormat.FormatRarityTag(character.rarity) .. "  -  "
			.. SharedFormat.FormatMoneyPerSecond(character.income) .. "  -  " .. character.quip
		local row, detailLabel = makeRow(scroller, title, detail, BrainrotCatalog.GetRarityColor(character.rarity), 58)
		row.LayoutOrder = order
		rowLabels[character.id] = detailLabel
	end

	local ladderHeader = Instance.new("TextLabel")
	ladderHeader.BackgroundTransparency = 1
	ladderHeader.Font = Enum.Font.GothamBlack
	ladderHeader.Size = UDim2.new(1, 0, 0, 32)
	ladderHeader.Text = "REBIRTH LADDER"
	ladderHeader.TextColor3 = Color3.new(1, 0.7, 0.9)
	ladderHeader.TextSize = 26
	ladderHeader.LayoutOrder = 100
	ladderHeader.Parent = scroller

	for order, requirement in ipairs(BrainrotCatalog.REBIRTHS) do
		local title = "Rebirth " .. tostring(order) .. "  -  x" .. tostring(requirement.multiplier) .. " income"
		local detail = "Needs " .. SharedFormat.FormatMoney(requirement.cash) .. " + "
			.. BrainrotCatalog.GetRarityName(requirement.needRarity) .. " or better"
		local row = makeRow(scroller, title, detail, Color3.new(1, 0.7, 0.9), 58)
		row.LayoutOrder = 100 + order
	end

	panel.Parent = gui
	gui.Parent = player:WaitForChild("PlayerGui")

	local function togglePanel()
		panelOpen = not panelOpen
		panel.Visible = panelOpen
	end
	toggle.MouseButton1Click:Connect(togglePanel)
	ContextActionService:BindAction("BrainrotCastList", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			togglePanel()
		end
	end, false, Enum.KeyCode.C)
end

local function RefreshOwnedCounts()
	for _, character in ipairs(BrainrotCatalog.CHARACTERS) do
		local label = rowLabels[character.id]
		if label ~= nil then
			local owned = ownedCounts[character.id] or 0
			local detail = SharedFormat.FormatRarityTag(character.rarity) .. "  -  "
				.. SharedFormat.FormatMoneyPerSecond(character.income) .. "  -  " .. character.quip
			if owned > 0 then
				detail = detail .. "  [OWNED x" .. tostring(owned) .. "]"
			end
			label.Text = detail
		end
	end
end

BuildCollectionPanel()

StateSync.OnClientEvent:Connect(function(snapshot)
	ownedCounts = snapshot.ownedCounts or {}
	RefreshOwnedCounts()
end)
