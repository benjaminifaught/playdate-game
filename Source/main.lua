import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/timer"
import "levels"
import "player"

local gfx = playdate.graphics
local textAlignment = kTextAlignment
local levels = playdate._fulfillmentFrenzyLevels
local Player = playdate._fulfillmentFrenzyPlayer
playdate._fulfillmentFrenzyLevels = nil
playdate._fulfillmentFrenzyPlayer = nil

local SCREEN_WIDTH = 400
local SCREEN_HEIGHT = 240
local FLOOR_Y = 220
local HUD_HEIGHT = 20

local START_MENU = "START_MENU"
local PLAYING = "PLAYING"
local LEVEL_CLEAR = "LEVEL_CLEAR"
local GAME_OVER = "GAME_OVER"

local gameState = START_MENU
local currentLevelIndex = 1
local currentLevel = levels[currentLevelIndex]
local player = nil
local floor = nil
local levelTimer = nil
local levelStartTime = 0

local function drawFloor(sprite, x, y, width, height)
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(x, y, width, height)
end

local function removeLevelSprites()
	if player ~= nil then
		player:remove()
		player = nil
	end

	if floor ~= nil then
		floor:remove()
		floor = nil
	end
end

local function createFloor()
	floor = gfx.sprite.new()
	floor:setSize(SCREEN_WIDTH, SCREEN_HEIGHT - FLOOR_Y)
	floor:setCollideRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - FLOOR_Y)
	floor:setGroups({ 1 })
	floor:setCollidesWithGroups({ 2 })
	floor:setZIndex(0)
	floor.draw = drawFloor
	floor:moveTo(SCREEN_WIDTH / 2, FLOOR_Y + (SCREEN_HEIGHT - FLOOR_Y) / 2)
	floor:add()
end

local function startLevel(index)
	removeLevelSprites()

	currentLevelIndex = index
	currentLevel = levels[currentLevelIndex]
	if levelTimer ~= nil then
		levelTimer:remove()
	end

	levelTimer = playdate.timer.new(currentLevel.timeLimit * 1000, function()
		if gameState == PLAYING then
			gameState = GAME_OVER
		end
	end)
	levelStartTime = playdate.getCurrentTimeMilliseconds()

	createFloor()
	player = Player(currentLevel.playerStartX, currentLevel.playerStartY)
	gameState = PLAYING
end

local function drawHud()
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(0, 0, SCREEN_WIDTH, HUD_HEIGHT)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	local elapsedSeconds = (playdate.getCurrentTimeMilliseconds() - levelStartTime) / 1000
	local timeRemaining = math.max(0, currentLevel.timeLimit - elapsedSeconds)
	gfx.drawText(
		"LEVEL " .. currentLevel.levelNumber .. "   TIME " .. math.ceil(timeRemaining),
		8,
		2
	)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

local function update()
	gfx.clear(gfx.kColorWhite)

	if gameState == START_MENU then
		gfx.drawTextAligned("FULFILLMENT FRENZY", SCREEN_WIDTH / 2, 82, textAlignment.center)
		gfx.drawTextAligned("Press A to start", SCREEN_WIDTH / 2, 122, textAlignment.center)
		if playdate.buttonJustPressed(playdate.kButtonA) then
			startLevel(1)
		end
	elseif gameState == PLAYING then
		playdate.timer.updateTimers()
		gfx.sprite.update()
		drawHud()

		if player ~= nil and player.x >= SCREEN_WIDTH - 8 then
			gameState = LEVEL_CLEAR
		end
	elseif gameState == LEVEL_CLEAR then
		gfx.drawTextAligned("LEVEL CLEAR!", SCREEN_WIDTH / 2, 82, textAlignment.center)
		if currentLevelIndex < #levels then
			gfx.drawTextAligned("Press A for the next level", SCREEN_WIDTH / 2, 122, textAlignment.center)
			if playdate.buttonJustPressed(playdate.kButtonA) then
				startLevel(currentLevelIndex + 1)
			end
		else
			gfx.drawTextAligned("All levels complete!", SCREEN_WIDTH / 2, 122, textAlignment.center)
			if playdate.buttonJustPressed(playdate.kButtonA) then
				gameState = START_MENU
			end
		end
	elseif gameState == GAME_OVER then
		gfx.drawTextAligned("TIME'S UP!", SCREEN_WIDTH / 2, 82, textAlignment.center)
		gfx.drawTextAligned("Press A to try again", SCREEN_WIDTH / 2, 122, textAlignment.center)
		if playdate.buttonJustPressed(playdate.kButtonA) then
			startLevel(currentLevelIndex)
		end
	end
end

playdate.update = update
