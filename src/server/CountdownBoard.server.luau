-- CountdownBoard: the live market board above the belt. It shows the real
-- seconds until the next tsunami from TsunamiController's schedule, the
-- wave state while a wave runs, and the real pity countdowns from
-- GameState. Every value on the board comes from the live game; nothing is
-- static or invented.

local Workspace = game:GetService("Workspace")

local GameState = require(script.Parent.GameState)
local TsunamiController = require(script.Parent.TsunamiController)

local board = Workspace:WaitForChild("CountdownBoard")

local faces = {}
for _, guiName in ipairs({ "BoardGuiFront", "BoardGuiBack" }) do
	local gui = board:FindFirstChild(guiName)
	if gui ~= nil then
		local title = gui:FindFirstChild("TitleLabel")
		local timeLabel = gui:FindFirstChild("TimeLabel")
		local pity = gui:FindFirstChild("PityLabel")
		if title ~= nil and timeLabel ~= nil and pity ~= nil then
			table.insert(faces, { title = title, time = timeLabel, pity = pity })
		end
	end
end

local function formatClock(seconds)
	local total = math.max(0, math.ceil(seconds))
	local minutes = math.floor(total / 60)
	local rest = total % 60
	return string.format("%02d:%02d", minutes, rest)
end

local function formatPity(remaining, label)
	if remaining <= 0 then
		return label .. " PITY LIVE"
	end
	return label .. " PITY " .. formatClock(remaining)
end

while true do
	task.wait(0.25)
	local titleText = "NEXT TSUNAMI"
	local timeText = formatClock(TsunamiController.GetSecondsUntilNextWave())
	local timeColor = Color3.new(1, 1, 1)
	if TsunamiController.IsWaveRunning() then
		titleText = "TSUNAMI"
		timeText = "WAVE IS HERE!"
		timeColor = Color3.new(1, 0.35, 0.3)
	end
	local legendaryRemaining, mythicRemaining = GameState.GetPityCountdowns()
	local pityText = "PITY TIMERS START WHEN PLAYERS JOIN"
	if legendaryRemaining ~= nil and mythicRemaining ~= nil then
		pityText = formatPity(legendaryRemaining, "LEGENDARY") .. "  |  " .. formatPity(mythicRemaining, "MYTHIC")
	end
	for _, face in ipairs(faces) do
		face.title.Text = titleText
		face.time.Text = timeText
		face.time.TextColor3 = timeColor
		face.pity.Text = pityText
	end
end
