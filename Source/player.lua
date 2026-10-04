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

local playerNamespace = {}
class("Player", {}, playerNamespace).extends(sprite)
local Player = playerNamespace.Player

function Player:init(startX, startY)
	Player.super.init(self)

	self:setImage(gfx.image.new(PLAYER_WIDTH, PLAYER_HEIGHT, gfx.kColorBlack))
	self:setCollideRect(0, 0, PLAYER_WIDTH, PLAYER_HEIGHT)
	self:setGroups({ 2 })
	self:setCollidesWithGroups({ 1 })
	self:setZIndex(10)
	self:moveTo(startX, startY)
	self:add()

	self.velocityX = 0
	self.velocityY = 0
	self.onGround = false
	self.lastUpdateTime = playdate.getCurrentTimeMilliseconds()
end

function Player:update()
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

	local _, _, collisions, collisionCount = self:moveWithCollisions(
		self.x + self.velocityX * deltaTime,
		self.y + self.velocityY * deltaTime
	)

	self.onGround = false
	for i = 1, collisionCount do
		local normalY = collisions[i].normal.y
		if normalY < 0 then
			self.velocityY = 0
			self.onGround = true
		elseif normalY > 0 then
			self.velocityY = 0
		end
	end
end

-- Hand the class to main.lua through Playdate's import-compatible module slot.
playdate._fulfillmentFrenzyPlayer = Player
