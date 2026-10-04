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
local BOX_WIDTH = 36
local BOX_HEIGHT = 28
local ITEM_SIZE = 14
local INTERACT_DISTANCE = 30
local CRANK_DEGREES_TO_TAPE = 180
local HAZARD_GROUP = 3

local START_MENU = "START_MENU"
local LEVEL_BRIEFING = "LEVEL_BRIEFING"
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
local itemSprite = nil
local boxSprite = nil
local floorSprites = {}
local obstacleSprites = {}
local platformSprites = {}
local hazardSprites = {}
local backdropSprites = {}
local sceneSprites = {}
local itemCollected = false
local itemPlaced = false
local tapeProgress = 0
local gameOverMessage = "SHIFT FAILED"
local cameraX = 0
local worldWidth = SCREEN_WIDTH

local function drawFloor(sprite, x, y, width, height)
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(x, y, width, height)
end

local function drawParcel(sprite, x, y, width, height)
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(x, y, width, height)
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRect(x + width / 2 - 1, y, 2, height)
	gfx.drawLine(x, y + height / 2, x + width - 1, y + height / 2)
end

local function drawShippingBox(sprite, x, y, width, height)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRect(x, y, width, height)
	gfx.drawLine(x + 1, y + 7, x + width - 2, y + 7)
	gfx.drawLine(x + width / 2, y + 1, x + width / 2, y + 7)
	if itemPlaced and tapeProgress >= CRANK_DEGREES_TO_TAPE then
		gfx.fillRect(x + width / 2 - 2, y + 1, 4, height - 2)
	end
end

local function drawObstacle(sprite, x, y, width, height)
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(x, y, width, height)
	gfx.setColor(gfx.kColorWhite)
	for stripeX = x + 3, x + width - 5, 8 do
		gfx.drawLine(stripeX, y + 2, math.min(stripeX + 4, x + width - 2), y + 2)
	end
end

local function drawPlatform(sprite, x, y, width, height)
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(x, y, width, height)
	gfx.setColor(gfx.kColorWhite)
	for lineX = x + 4, x + width - 4, 12 do
		gfx.drawLine(lineX, y + 2, math.min(lineX + 5, x + width - 2), y + 2)
	end
end

local function drawBackdrop(sprite, x, y, width, height)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawLine(x + 8, y + 8, x + width - 8, y + 8)
	gfx.drawLine(x + 8, y + 8, x + 8, y + 18)
	gfx.drawLine(x + width - 8, y + 8, x + width - 8, y + 18)
	gfx.drawTextAligned(
		"WAREHOUSE  /  " .. currentLevel.name,
		x + width / 2,
		y + 12,
		textAlignment.center
	)
	gfx.drawLine(x + width - 1, y + 20, x + width - 1, y + height)
end

local function registerSceneSprite(sprite)
	sceneSprites[#sceneSprites + 1] = sprite
	return sprite
end

local function renderSceneAtCamera()
	for i = 1, #sceneSprites do
		sceneSprites[i]:moveBy(-cameraX, 0)
	end
	gfx.sprite.update()
	for i = 1, #sceneSprites do
		sceneSprites[i]:moveBy(cameraX, 0)
	end
end

local function drawForklift(sprite, x, y, width, height)
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(x + 2, y + 7, width - 4, height - 10)
	gfx.fillRect(x + width - 6, y + 1, 4, height - 3)
	gfx.fillRect(x + width - 2, y + 1, 2, height - 3)
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRect(x + 5, y + 9, 7, 4)
	gfx.drawLine(x + width - 8, y + 8, x + width - 3, y + 8)
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(x + 4, y + height - 4, 5, 4)
	gfx.fillRect(x + width - 10, y + height - 4, 5, 4)
end

local function updateForklift(sprite)
	local now = playdate.getCurrentTimeMilliseconds()
	local deltaTime = math.min((now - sprite.lastUpdateTime) / 1000, 0.05)
	sprite.lastUpdateTime = now

	local nextX = sprite.x + sprite.speed * deltaTime
	if nextX < sprite.minX then
		nextX = sprite.minX
		sprite.speed = math.abs(sprite.speed)
	elseif nextX > sprite.maxX then
		nextX = sprite.maxX
		sprite.speed = -math.abs(sprite.speed)
	end
	sprite:moveTo(nextX, sprite.y)
end

local function isNearPlayer(x, y, distance)
	return player ~= nil
		and math.abs(player.x - x) <= distance
		and math.abs(player.y - y) <= distance
end

local function removeLevelSprites()
	if player ~= nil then
		player:remove()
		player = nil
	end

	if floor ~= nil then
		for i = 1, #floorSprites do
			floorSprites[i]:remove()
		end
		floorSprites = {}
		floor = nil
	end

	if itemSprite ~= nil then
		itemSprite:remove()
		itemSprite = nil
	end
	if boxSprite ~= nil then
		boxSprite:remove()
		boxSprite = nil
	end
	for i = 1, #obstacleSprites do
		obstacleSprites[i]:remove()
	end
	obstacleSprites = {}
	for i = 1, #platformSprites do
		platformSprites[i]:remove()
	end
	platformSprites = {}
	for i = 1, #hazardSprites do
		hazardSprites[i]:remove()
	end
	hazardSprites = {}
	for i = 1, #backdropSprites do
		backdropSprites[i]:remove()
	end
	backdropSprites = {}
	sceneSprites = {}
end

local function createFloor()
	for page = 0, currentLevel.pageCount - 1 do
		local floorSprite = registerSceneSprite(gfx.sprite.new())
		floorSprite:setSize(SCREEN_WIDTH, SCREEN_HEIGHT - FLOOR_Y)
		floorSprite:setCollideRect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - FLOOR_Y)
		floorSprite:setGroups({ 1 })
		floorSprite:setCollidesWithGroups({ 2 })
		floorSprite:setZIndex(0)
		floorSprite.draw = drawFloor
		floorSprite:moveTo(
			page * SCREEN_WIDTH + SCREEN_WIDTH / 2,
			FLOOR_Y + (SCREEN_HEIGHT - FLOOR_Y) / 2
		)
		floorSprite:add()
		floorSprites[#floorSprites + 1] = floorSprite
	end
	floor = floorSprites[1]
end

local function createLevelObjects()
	for page = 0, currentLevel.pageCount - 1 do
		local backdrop = gfx.sprite.new()
		backdrop:setCenter(0, 0)
		backdrop:setSize(SCREEN_WIDTH, FLOOR_Y - HUD_HEIGHT)
		backdrop:setZIndex(-10)
		backdrop.draw = drawBackdrop
		backdrop:moveTo(page * SCREEN_WIDTH, HUD_HEIGHT)
		registerSceneSprite(backdrop):add()
		backdropSprites[#backdropSprites + 1] = backdrop
	end

	itemSprite = registerSceneSprite(gfx.sprite.new())
	itemSprite:setSize(ITEM_SIZE, ITEM_SIZE)
	itemSprite:setZIndex(2)
	itemSprite.draw = drawParcel
	itemSprite:moveTo(currentLevel.itemX, currentLevel.itemY)
	itemSprite:add()

	boxSprite = registerSceneSprite(gfx.sprite.new())
	boxSprite:setSize(BOX_WIDTH, BOX_HEIGHT)
	boxSprite:setZIndex(2)
	boxSprite.draw = drawShippingBox
	boxSprite:moveTo(currentLevel.boxX, currentLevel.boxY)
	boxSprite:add()

	for i = 1, #currentLevel.obstacles do
		local obstacle = currentLevel.obstacles[i]
		local obstacleSprite = registerSceneSprite(gfx.sprite.new())
		obstacleSprite:setSize(obstacle.width, obstacle.height)
		obstacleSprite:setCollideRect(0, 0, obstacle.width, obstacle.height)
		obstacleSprite:setGroups({ 1 })
		obstacleSprite:setCollidesWithGroups({ 2 })
		obstacleSprite:setZIndex(1)
		obstacleSprite.draw = drawObstacle
		obstacleSprite:moveTo(
			obstacle.x,
			FLOOR_Y - obstacle.height / 2
		)
		obstacleSprite:add()
		obstacleSprites[i] = obstacleSprite
	end

	local function addPlatform(x, y, width, height, isOneWay)
		local platform = registerSceneSprite(gfx.sprite.new())
		platform:setSize(width, height)
		platform:setCollideRect(0, 0, width, height)
		platform:setGroups({ 1 })
		platform:setCollidesWithGroups({ 2 })
		platform:setZIndex(1)
		platform.draw = drawPlatform
		platform.isOneWayPlatform = isOneWay
		platform.platformTop = y - height / 2
		platform:moveTo(x, y)
		platform:add()
		platformSprites[#platformSprites + 1] = platform
	end

	for i = 1, #currentLevel.platforms do
		local platform = currentLevel.platforms[i]
		addPlatform(platform.x, platform.y, platform.width, platform.height, true)
	end

	for i = 1, #currentLevel.stairs do
		local stair = currentLevel.stairs[i]
		for step = 1, stair.count do
			local x = stair.x + (step - 1) * stair.stepWidth * stair.direction
			local topY = stair.baseY - step * stair.stepHeight
			addPlatform(
				x,
				topY + stair.stepHeight / 2,
				stair.stepWidth,
				stair.stepHeight,
				false
			)
		end
	end

	for i = 1, #currentLevel.hazards do
		local hazard = currentLevel.hazards[i]
		local hazardSprite = registerSceneSprite(gfx.sprite.new())
		hazardSprite:setSize(hazard.width, hazard.height)
		hazardSprite:setCollideRect(0, 0, hazard.width, hazard.height)
		hazardSprite:setGroups({ HAZARD_GROUP })
		hazardSprite:setCollidesWithGroups({ 2 })
		hazardSprite.isHazard = true
		hazardSprite:setZIndex(3)
		hazardSprite.draw = drawForklift
		hazardSprite:setUpdatesEnabled(false)
		hazardSprite.minX = hazard.minX
		hazardSprite.maxX = hazard.maxX
		hazardSprite.speed = hazard.speed
		hazardSprite.lastUpdateTime = playdate.getCurrentTimeMilliseconds()
		hazardSprite:moveTo(hazard.x, FLOOR_Y - hazard.height / 2)
		hazardSprites[i] = hazardSprite
		hazardSprite:add()
	end
end

local function startLevel(index)
	removeLevelSprites()

	currentLevelIndex = index
	currentLevel = levels[currentLevelIndex]
	worldWidth = currentLevel.pageCount * SCREEN_WIDTH
	cameraX = 0
	if levelTimer ~= nil then
		levelTimer:remove()
		levelTimer = nil
	end

	itemCollected = false
	itemPlaced = false
	tapeProgress = 0
	gameOverMessage = "SHIFT FAILED"

	createFloor()
	createLevelObjects()
	player = Player(currentLevel.playerStartX, currentLevel.playerStartY, worldWidth)
	player:setUpdatesEnabled(false)
	registerSceneSprite(player)
	gameState = LEVEL_BRIEFING
end

local function beginShift()
	levelStartTime = playdate.getCurrentTimeMilliseconds()
	levelTimer = playdate.timer.new(currentLevel.timeLimit * 1000, function()
		if gameState == PLAYING then
			gameOverMessage = "TIME'S UP!"
			gameState = GAME_OVER
		end
	end)
	for i = 1, #hazardSprites do
		hazardSprites[i].lastUpdateTime = levelStartTime
	end
	gameState = PLAYING
end

local function drawHud()
	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(0, 0, SCREEN_WIDTH, HUD_HEIGHT)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	local elapsedSeconds = (playdate.getCurrentTimeMilliseconds() - levelStartTime) / 1000
	local timeRemaining = math.max(0, currentLevel.timeLimit - elapsedSeconds)
	local objective = "GET ITEM"
	if itemCollected and not itemPlaced then
		objective = "DELIVER ITEM"
	elseif itemPlaced and tapeProgress < CRANK_DEGREES_TO_TAPE then
		objective = "TAPE " .. math.floor(tapeProgress / CRANK_DEGREES_TO_TAPE * 100) .. "%"
	elseif itemPlaced then
		objective = "BOX SEALED"
	end
	local playerWorldX = 0
	if player ~= nil then
		playerWorldX = player.worldX
	end
	local currentPage = math.floor(playerWorldX / SCREEN_WIDTH) + 1
	gfx.drawText(
		"L" .. currentLevel.levelNumber .. "  PG " .. currentPage .. "/" .. currentLevel.pageCount
			.. "  " .. math.ceil(timeRemaining) .. "s",
		6,
		2
	)
	gfx.drawTextAligned(objective, SCREEN_WIDTH - 8, 2, textAlignment.right)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

local function interact()
	if playdate.buttonJustPressed(playdate.kButtonB) then
		if not itemCollected and isNearPlayer(currentLevel.itemX, currentLevel.itemY, INTERACT_DISTANCE) then
			itemCollected = true
			if itemSprite ~= nil then
				itemSprite:remove()
				itemSprite = nil
			end
			if player ~= nil then
				player.isCarrying = true
			end
		elseif itemCollected
			and not itemPlaced
			and isNearPlayer(currentLevel.boxX, currentLevel.boxY, INTERACT_DISTANCE)
		then
			itemPlaced = true
			if player ~= nil then
				player.isCarrying = false
			end
		end
	end
end

local function onCranked(change)
	if gameState == PLAYING
		and itemPlaced
		and tapeProgress < CRANK_DEGREES_TO_TAPE
		and isNearPlayer(currentLevel.boxX, currentLevel.boxY, INTERACT_DISTANCE)
	then
		tapeProgress = math.min(tapeProgress + math.abs(change), CRANK_DEGREES_TO_TAPE)
		if tapeProgress >= CRANK_DEGREES_TO_TAPE then
			gameState = LEVEL_CLEAR
		end
	end
end

local function update()
	gfx.setDrawOffset(0, 0)
	gfx.clear(gfx.kColorWhite)

	if gameState == START_MENU then
		gfx.drawTextAligned("FULFILLMENT FRENZY", SCREEN_WIDTH / 2, 82, textAlignment.center)
		gfx.drawTextAligned("LEFT / RIGHT: MOVE     A: JUMP", SCREEN_WIDTH / 2, 116, textAlignment.center)
		gfx.drawTextAligned("B: PICK UP / PLACE     CRANK: TAPE", SCREEN_WIDTH / 2, 136, textAlignment.center)
		if playdate.buttonJustPressed(playdate.kButtonA) then
			startLevel(1)
		end
	elseif gameState == LEVEL_BRIEFING then
		gfx.setColor(gfx.kColorBlack)
		gfx.fillRect(24, 36, 352, 168)
		gfx.setColor(gfx.kColorWhite)
		gfx.drawRect(28, 40, 344, 160)
		gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
		gfx.drawTextAligned("SHIFT " .. currentLevel.levelNumber .. ": " .. currentLevel.name, SCREEN_WIDTH / 2, 52, textAlignment.center)
		gfx.drawTextAligned(currentLevel.briefing, SCREEN_WIDTH / 2, 82, textAlignment.center)
		gfx.drawTextAligned(currentLevel.instruction, SCREEN_WIDTH / 2, 106, textAlignment.center)
		gfx.drawTextAligned("D-PAD MOVE   A JUMP   B PICK UP / PLACE", SCREEN_WIDTH / 2, 136, textAlignment.center)
		gfx.drawTextAligned("AVOID FORKLIFTS  -  " .. currentLevel.timeLimit .. " SECONDS", SCREEN_WIDTH / 2, 156, textAlignment.center)
		gfx.drawTextAligned("PRESS A TO START SHIFT", SCREEN_WIDTH / 2, 178, textAlignment.center)
		gfx.setImageDrawMode(gfx.kDrawModeCopy)
		if playdate.buttonJustPressed(playdate.kButtonA) then
			beginShift()
		end
	elseif gameState == PLAYING then
		playdate.timer.updateTimers()
		if player ~= nil then
			player:update()
		end
		for i = 1, #hazardSprites do
			updateForklift(hazardSprites[i])
		end
		if player ~= nil then
			cameraX = math.max(
				0,
				math.min(player.worldX - SCREEN_WIDTH / 2, worldWidth - SCREEN_WIDTH)
			)
		end
		renderSceneAtCamera()
		interact()
		drawHud()

		if player ~= nil and player.hitHazard then
			gameOverMessage = "HIT BY A FORKLIFT!"
			gameState = GAME_OVER
		end
	elseif gameState == LEVEL_CLEAR then
		gfx.drawTextAligned("SHIFT COMPLETE!", SCREEN_WIDTH / 2, 82, textAlignment.center)
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
		gfx.drawTextAligned(gameOverMessage, SCREEN_WIDTH / 2, 82, textAlignment.center)
		gfx.drawTextAligned("PRESS A TO RESTART THIS SHIFT", SCREEN_WIDTH / 2, 122, textAlignment.center)
		if playdate.buttonJustPressed(playdate.kButtonA) then
			startLevel(currentLevelIndex)
		end
	end
end

playdate.update = update
playdate.cranked = onCranked
