local gfx = playdate.graphics
local sprite = gfx.sprite
local abs = math.abs
local class = class

local PLAYER_WIDTH = 16
local PLAYER_HEIGHT = 32
local MAX_HORIZONTAL_SPEED = 110
local GROUND_ACCELERATION = 520
local AIR_ACCELERATION = 320
local GROUND_DECELERATION = 700
local GRAVITY = 900
local MAX_FALL_SPEED = 420
local JUMP_SPEED = 330
local MAX_DELTA_TIME = 0.05
local WORLD_LEFT = PLAYER_WIDTH / 2

local function makeWorkerImage(isCarrying)
	local imageWidth = PLAYER_WIDTH
	local image = gfx.image.new(imageWidth, PLAYER_HEIGHT, gfx.kColorClear)
	gfx.lockFocus(image)
	gfx.setColor(gfx.kColorBlack)

	-- Hard hat, face, and high-visibility work jacket.
	gfx.fillRect(4, 1, 8, 3)
	gfx.fillRect(2, 4, 12, 2)
	gfx.fillRect(5, 6, 6, 6)
	gfx.fillRect(7, 12, 3, 2)
	gfx.fillRect(3, 14, 10, 10)
	gfx.fillRect(1, 15, 3, 7)
	gfx.fillRect(12, 15, 3, 7)

	gfx.setColor(gfx.kColorWhite)
	gfx.drawLine(4, 17, 11, 17)
	gfx.drawLine(4, 21, 11, 21)
	gfx.fillRect(6, 8, 1, 1)
	gfx.fillRect(10, 8, 1, 1)

	gfx.setColor(gfx.kColorBlack)
	gfx.fillRect(4, 24, 4, 6)
	gfx.fillRect(9, 24, 4, 6)
	gfx.fillRect(2, 29, 6, 3)
	gfx.fillRect(9, 29, 6, 3)

	if isCarrying then
		gfx.fillRect(0, 17, 4, 5)
		gfx.setColor(gfx.kColorWhite)
		gfx.drawLine(1, 19, 3, 19)
	end

	gfx.unlockFocus()
	return image
end

local workerImage = makeWorkerImage(false)
local carryingWorkerImage = makeWorkerImage(true)

local playerNamespace = {}
class("Player", {}, playerNamespace).extends(sprite)
local Player = playerNamespace.Player

function Player:init(startX, startY, worldWidth)
	Player.super.init(self)

	self:setImage(workerImage)
	self:setCollideRect(0, 0, PLAYER_WIDTH, PLAYER_HEIGHT)
	self:setGroups({ 2 })
	self:setCollidesWithGroups({ 1, 3 })
	self:setZIndex(10)
	self:moveTo(startX, startY)
	self:add()

	self.worldX = startX
	self.worldRight = worldWidth - PLAYER_WIDTH / 2
	self.velocityX = 0
	self.velocityY = 0
	self.onGround = false
	self.isCarrying = false
	self.displayedCarrying = false
	self.hitHazard = false
	self.lastUpdateTime = playdate.getCurrentTimeMilliseconds()
end

function Player:collisionResponse(other)
	if other.isHazard then
		return "overlap"
	end
	if other.isOneWayPlatform then
		if self.velocityY > 0 and self.previousBottom <= other.platformTop then
			return "slide"
		end
		return "overlap"
	end
	return "slide"
end

function Player:update()
	self.hitHazard = false
	if self.displayedCarrying ~= self.isCarrying then
		self.displayedCarrying = self.isCarrying
		self:setImage(self.isCarrying and carryingWorkerImage or workerImage)
	end

	local now = playdate.getCurrentTimeMilliseconds()
	local deltaTime = (now - self.lastUpdateTime) / 1000
	self.lastUpdateTime = now
	deltaTime = math.min(deltaTime, MAX_DELTA_TIME)

	local moveLeft = playdate.buttonIsPressed(playdate.kButtonLeft)
	local moveRight = playdate.buttonIsPressed(playdate.kButtonRight)
	local acceleration = self.onGround and GROUND_ACCELERATION or AIR_ACCELERATION

	if moveLeft ~= moveRight then
		local direction = moveLeft and -1 or 1
		self.velocityX = self.velocityX + direction * acceleration * deltaTime
	elseif self.onGround then
		local speed = abs(self.velocityX)
		local deceleration = math.min(speed, GROUND_DECELERATION * deltaTime)
		if speed > 0 then
			self.velocityX = self.velocityX - (self.velocityX / speed) * deceleration
		end
	end

	self.velocityX = math.max(-MAX_HORIZONTAL_SPEED, math.min(self.velocityX, MAX_HORIZONTAL_SPEED))

	if self.onGround and playdate.buttonJustPressed(playdate.kButtonA) then
		self.velocityY = -JUMP_SPEED
		self.onGround = false
	end

	self.velocityY = math.min(self.velocityY + GRAVITY * deltaTime, MAX_FALL_SPEED)

	local nextX = math.max(
		WORLD_LEFT,
		math.min(self.x + self.velocityX * deltaTime, self.worldRight)
	)
	self.previousBottom = self.y + PLAYER_HEIGHT / 2

	local _, _, collisions, collisionCount = self:moveWithCollisions(nextX, self.y)
	for i = 1, collisionCount do
		if collisions[i].other.isHazard then
			self.hitHazard = true
		elseif not collisions[i].other.isOneWayPlatform and collisions[i].normal.x ~= 0 then
			self.velocityX = 0
		end
	end

	_, _, collisions, collisionCount = self:moveWithCollisions(
		self.x,
		self.y + self.velocityY * deltaTime
	)
	self.onGround = false
	for i = 1, collisionCount do
		if collisions[i].other.isHazard then
			self.hitHazard = true
		end
		local normalY = collisions[i].normal.y
		local other = collisions[i].other
		local landedOnOneWay = other.isOneWayPlatform
			and self.velocityY > 0
			and self.previousBottom <= other.platformTop
		if other.isOneWayPlatform and not landedOnOneWay then
			-- Pass upward through shelves and raised floors.
		elseif normalY < 0 then
			self.velocityY = 0
			self.onGround = true
		elseif normalY > 0 then
			self.velocityY = 0
		end
	end
	self.worldX = self.x
end

-- Hand the class to main.lua through Playdate's import-compatible module slot.
playdate._fulfillmentFrenzyPlayer = Player
