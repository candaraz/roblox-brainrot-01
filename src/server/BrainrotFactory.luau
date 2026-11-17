-- BrainrotFactory: builds every brainrot character model from Parts, with no
-- external asset ids, decals or sounds. Each model is a set of anchored
-- parts from the catalog recipe plus a BillboardGui label that names the
-- character, its rarity, its money per second and its price in big text.

local BrainrotCatalog = require(game:GetService("ReplicatedStorage"):WaitForChild("BrainrotCatalog"))
local SharedFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("SharedFormat"))

local BrainrotFactory = {}

local function colourForRole(character, role)
	if role == "accent" then
		return Color3.new(character.accent[1], character.accent[2], character.accent[3])
	end
	if role == "detail" then
		return Color3.new(character.detail[1], character.detail[2], character.detail[3])
	end
	return Color3.new(character.body[1], character.body[2], character.body[3])
end

local function makeFeaturePart(spec, character, scale, origin)
	local shape, size, offset, role, transparency = spec[1], spec[2], spec[3], spec[4], spec[5]
	local part
	if shape == "Wedge" then
		part = Instance.new("WedgePart")
	else
		part = Instance.new("Part")
		if shape == "Ball" then
			part.Shape = Enum.PartType.Ball
		elseif shape == "Cylinder" then
			part.Shape = Enum.PartType.Cylinder
		end
	end
	part.Size = Vector3.new(size[1] * scale, size[2] * scale, size[3] * scale)
	part.Color = colourForRole(character, role)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	if transparency ~= nil then
		part.Transparency = transparency
	end
	local localOffset = CFrame.new(offset[1] * scale, offset[2] * scale, offset[3] * scale)
	if shape == "Cylinder" then
		-- A cylinder's axis runs along local X; turning it a quarter turn
		-- about Z stands it upright.
		localOffset = localOffset * CFrame.Angles(0, 0, math.rad(90))
	end
	part.CFrame = origin * localOffset
	part:SetAttribute("Role", role)
	return part
end

local function makeLabelledText(parent, name, position, size, textSize, colour)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = ""
	label.TextColor3 = colour
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Parent = label
	label.Parent = parent
	return label
end

local function makeBillboardLabel(character, mutationName)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.new(0, 260, 0, 120)
	gui.ExtentsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 160
	makeLabelledText(gui, "NameLabel", UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0.3, 0), 30, Color3.new(1, 1, 1))
	makeLabelledText(
		gui,
		"RarityLabel",
		UDim2.new(0, 0, 0.3, 0),
		UDim2.new(1, 0, 0.25, 0),
		24,
		BrainrotCatalog.GetRarityColor(character.rarity)
	)
	makeLabelledText(gui, "RateLabel", UDim2.new(0, 0, 0.55, 0), UDim2.new(1, 0, 0.25, 0), 26, Color3.new(0.4, 1, 0.4))
	makeLabelledText(gui, "PriceLabel", UDim2.new(0, 0, 0.8, 0), UDim2.new(1, 0, 0.2, 0), 24, Color3.new(1, 0.9, 0.3))
	BrainrotFactory.UpdateBrainrotLabel(gui, character, mutationName, "belt", nil)
	return gui
end

function BrainrotFactory.BuildBrainrotModel(characterId, mutationName, uid, spawnCFrame)
	local character = BrainrotCatalog.GetCharacter(characterId)
	local scale = character.scale
	if mutationName == "Divine" then
		scale = scale * 1.15
	end
	local model = Instance.new("Model")
	model.Name = character.name
	local primary = nil
	for index, spec in ipairs(character.parts) do
		local part = makeFeaturePart(spec, character, scale, spawnCFrame)
		part.Name = "Feature" .. tostring(index)
		if index == 1 then
			part.Name = "Body"
			primary = part
		end
		part.Parent = model
	end
	model.PrimaryPart = primary
	local label = makeBillboardLabel(character, mutationName)
	label.Parent = primary
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BrainrotPrompt"
	prompt.ActionText = "BUY"
	prompt.ObjectText = SharedFormat.FormatBrainrotTitle(character, mutationName)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt:SetAttribute("Kind", "buy")
	prompt:SetAttribute("Uid", uid)
	prompt.Parent = primary
	model:SetAttribute("Uid", uid)
	model:SetAttribute("CharacterId", characterId)
	if mutationName ~= nil then
		model:SetAttribute("Mutation", mutationName)
	end
	BrainrotFactory.ApplyMutationLook(model, character, mutationName)
	return model
end

function BrainrotFactory.ApplyMutationLook(model, character, mutationName)
	if mutationName == nil then
		return
	end
	local mutation = BrainrotCatalog.GetMutation(mutationName)
	local tint = Color3.new(mutation.color[1], mutation.color[2], mutation.color[3])
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("Role") == "body" then
			if mutationName == "Gold" then
				descendant.Color = tint
				descendant.Material = Enum.Material.Foil
			elseif mutationName == "Diamond" then
				descendant.Color = tint
				descendant.Transparency = 0.25
				descendant.Reflectance = 0.6
			elseif mutationName == "Divine" then
				descendant.Color = tint
				descendant.Material = Enum.Material.Neon
			elseif mutationName == "Rainbow" then
				descendant.Color = tint
				descendant.Material = Enum.Material.Neon
			end
		end
	end
end

function BrainrotFactory.UpdateBrainrotLabel(guiOrModel, character, mutationName, mode, ownerName)
	local gui = guiOrModel
	if guiOrModel:IsA("Model") then
		local primary = guiOrModel.PrimaryPart
		if primary == nil then
			return
		end
		gui = primary:FindFirstChild("BrainrotLabel")
	end
	if gui == nil then
		return
	end
	local nameLabel = gui:FindFirstChild("NameLabel")
	local rarityLabel = gui:FindFirstChild("RarityLabel")
	local rateLabel = gui:FindFirstChild("RateLabel")
	local priceLabel = gui:FindFirstChild("PriceLabel")
	if nameLabel ~= nil then
		nameLabel.Text = SharedFormat.FormatBrainrotTitle(character, mutationName)
	end
	if rarityLabel ~= nil then
		rarityLabel.Text = SharedFormat.FormatRarityTag(character.rarity)
	end
	if rateLabel ~= nil then
		rateLabel.Text = SharedFormat.FormatMoneyPerSecond(BrainrotCatalog.GetIncomeWithMutation(character, mutationName))
	end
	if priceLabel ~= nil then
		if mode == "belt" then
			priceLabel.Text = SharedFormat.FormatMoney(character.price)
		elseif mode == "placed" and ownerName ~= nil then
			priceLabel.Text = "Owned by " .. ownerName
		elseif mode == "carried" then
			priceLabel.Text = "STOLEN! SLAP TO SAVE!"
		else
			priceLabel.Text = ""
		end
	end
end

function BrainrotFactory.UpdateBrainrotPrompt(model, kind, actionText, objectText, enabled)
	local primary = model.PrimaryPart
	if primary == nil then
		return
	end
	local prompt = primary:FindFirstChild("BrainrotPrompt")
	if prompt == nil then
		return
	end
	prompt:SetAttribute("Kind", kind)
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.Enabled = enabled
end

function BrainrotFactory.GetModelRestHeight(characterId)
	local character = BrainrotCatalog.GetCharacter(characterId)
	return 2 * character.scale
end

return BrainrotFactory
