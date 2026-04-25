require("src.Item")

local CollisionAction = require("src.components.collision_action")
local CooldownAction = require("src.components.cooldown_action")
local Damageable = require("src.components.damageable")
local TimedCollisionUnlock = require("src.components.timed_collision_unlock")
local SeekTarget = require("src.components.seek_target")
local make_pooled = Batteries.make_pooled

Enemy = class({
	name = "Enemy",
	extends = Entity,
	default_tostring = true
})

EnemyType = {
	Normal = 1,
	Shielded = 2,
}

local ENEMY_VARIANTS = {
	[EnemyType.Normal] = {
		health = 1,
		fireCooldown = 0.5,
		rotateSpeed = 3,
		speedMultiplier = 1.0,
		dropItemChance = 0.1,
	},
	[EnemyType.Shielded] = {
		health = 1,
		fireCooldown = 0.42,
		rotateSpeed = 2.2,
		speedMultiplier = 1.05,
		dropItemChance = 0.12,
		hasFrontShield = true,
		shieldHalfAngle = math.rad(75),
		shieldRadius = 18,
	},
}

---@param enemyType integer
---@return table
local function get_enemy_variant(enemyType)
	return ENEMY_VARIANTS[enemyType] or ENEMY_VARIANTS[EnemyType.Normal]
end

---@param pos vec2
---@param rot? number
---@param scale vec2
---@param speed? number
---@param options? table
function Enemy:new(pos, rot, scale, speed, options)
	---@class Enemy : Entity
	options = options or {}
	self:super(pos, scale)
	self.enemyType = options.enemyType or EnemyType.Normal
	self.variant = get_enemy_variant(self.enemyType)
	self.speed = (speed or 10) * (self.variant.speedMultiplier or 1.0)
	self.hitbox = vec2(12, 12)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
	self.rotation = rot or 0
	self.health = options.health or self.variant.health or 1
	self.fireCooldown = options.fire_cooldown or self.variant.fireCooldown or 0.5
	self.rotateSpeed = options.rotate_speed or self.variant.rotateSpeed or 3
	self.dropItemChance = options.drop_item_chance or self.variant.dropItemChance or 0.1
	self.hasFrontShield = self.variant.hasFrontShield == true
	self.shieldHalfAngle = options.shield_half_angle or self.variant.shieldHalfAngle or 0
	self.shieldRadius = options.shield_radius or self.variant.shieldRadius or 16
	self.shieldFlashTimer = 0
	self.shieldFlashDuration = 0.1
    self:set_tag("enemy")
	if self.hasFrontShield then
		self:set_tag("shielded_enemy")
	end

    self:add_component("collision_unlock", TimedCollisionUnlock(1))
    self:add_component("seek_target", SeekTarget({
        speed = self.speed,
        rotateSpeed = self.rotateSpeed,
        targetTag = "player",
    }))
    self:add_component("weapon", CooldownAction({
        cooldown = self.fireCooldown,
        should_activate = function()
            return true
        end,
        ---@param entity Enemy
        ---@return boolean
        perform = function(entity)
            local projectile = entity:shoot()
            if not projectile then
                return false
            end

            entity:spawn(projectile)
            return true
        end,
    }))
    self:add_component("contact_damage", CollisionAction({
        targetTags = { "player" },
        consume_self = true,
        ---@param entity Enemy
        ---@param other Entity
        ---@return boolean
        action = function(entity, other)
            local damageable = other.get_component and other:get_component("damageable")
            if not damageable then
                return false
            end

            return damageable:apply_damage(other, 1, entity)
        end,
    }))
    self:add_component("damageable", Damageable({
        health = self.health,
        maxHealth = self.health,
        ---@param entity Enemy
        on_death = function(entity)
            entity:emit("enemy_killed", { enemy = entity })

            local dropItemChance = entity.dropItemChance or 0.1
            if math.random() < dropItemChance then
                entity:spawn(Item(entity.pos:copy(), vec2(2, 2), ItemType.Heart))
            end

            for _ = 1, 5 do
                local dir = math.random(-30, 30) / 10
                local distance = math.random(0, 5)
                BloodBatch:add(entity.pos.x + math.cos(dir)*distance, entity.pos.y + math.sin(dir)*distance, math.random(-30, 30) / 10, 3, 3, 6, 1)
            end
            love.audio.play(Sfx_explosion)
            entity:free()
        end,
    }))
end

---@param dt number
---@param context? table
function Enemy:update(dt, context)
	if self.shieldFlashTimer > 0 then
		self.shieldFlashTimer = math.max(0, self.shieldFlashTimer - dt)
	end
    Entity.update(self, dt, context)
end

---@return boolean
function Enemy:is_shielded()
	return self.hasFrontShield == true
end

---@param source Entity|nil
---@return boolean
function Enemy:is_source_blocked_by_shield(source)
	if not self:is_shielded() or not source or not source.pos then
		return false
	end

	local dx = source.pos.x - self.pos.x
	local dy = source.pos.y - self.pos.y
	local lenSq = dx * dx + dy * dy
	if lenSq <= 0.0001 then
		return false
	end

	local invLen = 1 / math.sqrt(lenSq)
	dx = dx * invLen
	dy = dy * invLen

	local forwardX = math.cos(self.rotation)
	local forwardY = math.sin(self.rotation)
	local frontDot = forwardX * dx + forwardY * dy
	return frontDot >= math.cos(self.shieldHalfAngle)
end

---@param source Entity|nil
---@param amount? integer
---@return boolean
function Enemy:receive_bullet_hit(source, amount)
	local damageable = self.get_component and self:get_component("damageable")
	if not damageable then
		return false
	end

	if self:is_source_blocked_by_shield(source) then
		self.shieldFlashTimer = self.shieldFlashDuration
		return true
	end

	return damageable:apply_damage(self, amount or 1, source)
end

function Enemy:draw_shield()
	if not self:is_shielded() then
		return
	end

	local radius = self.shieldRadius * math.max(self.scale.x, self.scale.y)
	local startAngle = self.rotation - self.shieldHalfAngle
	local endAngle = self.rotation + self.shieldHalfAngle
	local fillAlpha = self.shieldFlashTimer > 0 and 0.28 or 0.14
	local lineAlpha = self.shieldFlashTimer > 0 and 1.0 or 0.78

	love.graphics.setColor(0.2, 0.85, 1.0, fillAlpha)
	love.graphics.arc("fill", "pie", self.pos.x, self.pos.y, radius, startAngle, endAngle, 18)
	love.graphics.setColor(0.55, 1.0, 1.0, lineAlpha)
	love.graphics.setLineWidth(3)
	love.graphics.arc("line", "open", self.pos.x, self.pos.y, radius, startAngle, endAngle, 18)
	love.graphics.line(
		self.pos.x,
		self.pos.y,
		self.pos.x + math.cos(startAngle) * radius,
		self.pos.y + math.sin(startAngle) * radius
	)
	love.graphics.line(
		self.pos.x,
		self.pos.y,
		self.pos.x + math.cos(endAngle) * radius,
		self.pos.y + math.sin(endAngle) * radius
	)
	love.graphics.setLineWidth(2)
	love.graphics.setColor(PALETTE.white)
end

function Enemy:draw()
	local img = Assets.images.enemy
	love.graphics.draw(img, self.pos.x, self.pos.y, self.rotation + math.pi/2, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
	self:draw_shield()
end

---@param other Entity
function Enemy:onCollide(other)
    Entity.onCollide(self, other)
end

function Enemy:free()
	self.isValid = false
	Enemy.release(self)
end

---@return Bullet
function Enemy:shoot()
	local dir = vec2(math.cos(self.rotation), math.sin(self.rotation))
	local spawnPos = self.pos:copy() + 10 * dir
	return Bullet(spawnPos, self.rotation, vec2(2, 2), 240, BulletType.EnemyBullet)
end

make_pooled(Enemy, 120)
