-- SharedFormat: the money, rate and countdown text both the server labels and
-- the client HUD show. One formatting module, required by both sides, so a
-- number never reads two different ways in the same game.

local BrainrotCatalog = require(script.Parent.BrainrotCatalog)

local SharedFormat = {}

local SUFFIXES = {
	{ 1e12, "T" },
	{ 1e9, "B" },
	{ 1e6, "M" },
	{ 1e3, "K" },
}

function SharedFormat.FormatMoney(amount)
	amount = math.floor(amount + 0.5)
	for _, pair in ipairs(SUFFIXES) do
		local limit, suffix = pair[1], pair[2]
		if amount >= limit then
			local value = amount / limit
			if value >= 100 then
				return "$" .. tostring(math.floor(value + 0.5)) .. suffix
			end
			return "$" .. string.format("%.1f", value) .. suffix
		end
	end
	return "$" .. tostring(amount)
end

function SharedFormat.FormatMoneyPerSecond(income)
	return SharedFormat.FormatMoney(income) .. "/s"
end

function SharedFormat.FormatCountdown(seconds)
	seconds = math.max(0, math.ceil(seconds))
	local minutes = math.floor(seconds / 60)
	local rest = seconds - minutes * 60
	if minutes > 0 then
		return string.format("%d:%02d", minutes, rest)
	end
	return tostring(rest) .. "s"
end

function SharedFormat.FormatRarityTag(rarityIndex)
	return string.upper(BrainrotCatalog.GetRarityName(rarityIndex))
end

function SharedFormat.FormatMutationTag(mutationName)
	if mutationName == nil then
		return ""
	end
	return string.upper(mutationName) .. " "
end

function SharedFormat.FormatBrainrotTitle(character, mutationName)
	return SharedFormat.FormatMutationTag(mutationName) .. character.name
end

return SharedFormat
