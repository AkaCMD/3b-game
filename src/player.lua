local CooldownAction = require("src.components.cooldown_action")
local Damageable = require("src.components.damageable")
local Invulnerability = require("src.components.invulnerability")
local KeyboardMove = require("src.components.keyboard_move")
local LookAtTarget = require("src.components.look_at_target")

Player = class({
	name = "Player",
	extends = Entity,
	default_tostring = true
})

function Player:new(pos, scale)
	---@class Player: Entity
	self:super(pos, scale)
	self.lastPos = self.pos:copy()
	self.hitbox = vec2(8, 8)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
	self.health = 6
	self.isInvincible = false
    self.baseMoveSpeed = 200
    self.baseFireCooldown = 0.15
    self.boundaryBoostRemaining = 0
    self.upgradeLevels = {}
    self.upgrades = {
        bullet_scale = 1.0,
        move_speed_multiplier = 1.0,
        fire_rate_multiplier = 1.0,
        boundary_boost_enabled = false,
        boundary_boost_duration = 4.0,
        boundary_boost_move_multiplier = 1.35,
        boundary_boost_fire_multiplier = 1.25,
        bullet_boundary_warp_enabled = false,
    }
    self:set_tag("player")

    self:add_component("look_at_target", LookAtTarget({
        angle_offset = math.pi / 2,
    }))
    self:add_component("keyboard_move", KeyboardMove(self.baseMoveSpeed))
    self:add_component("weapon", CooldownAction({
        cooldown = self.baseFireCooldown,
        get_cooldown = function(entity, baseCooldown)
            return entity:get_auto_fire_cooldown(baseCooldown)
        end,
        should_activate = function()
            return love.mouse.isDown(1)
        end,
        perform = function(entity)
            local projectile = entity:shoot()
            if not projectile then
                return false
            end

            entity:spawn(projectile)
            return true
        end,
    }))
    self:add_component("invulnerability", Invulnerability(1))
    self:add_component("damageable", Damageable({
        health = 6,
        maxHealth = 6,
        invulnerabilityComponent = "invulnerability",
        on_damaged = function(entity, dmg)
            local invulnerability = entity:get_component("invulnerability")
            if invulnerability then
                invulnerability:trigger(entity)
            end
            entity:emit("player_take_damage", { player = entity, damage = dmg })
            love.audio.play(Sfx_hurt)
        end,
        on_death = function(entity)
            entity:free()
        end,
    }))
end

function Player:update(dt, context)
	self.lastPos = self.pos:copy()
    if self.boundaryBoostRemaining > 0 then
        self.boundaryBoostRemaining = math.max(0, self.boundaryBoostRemaining - dt)
    end
	Entity.update(self, dt, context)
end

function Player:keypressed(key)
	if key == "space" then
		self:explode()
	end
end

function Player:draw()
	Entity.draw(self)
	local img = Assets.images.fighter
	if self.lastPos.x > self.pos.x then
		love.graphics.draw(img, self.pos.x, self.pos.y, math.rad(-10) + self.rotation, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
	elseif self.lastPos.x < self.pos.x then
		love.graphics.draw(img, self.pos.x, self.pos.y, math.rad(10) + self.rotation, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
	else
		love.graphics.draw(img, self.pos.x, self.pos.y, self.rotation, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
	end
end

function Player:shoot()
	love.audio.play(Sfx_small_hit)
	local dir = vec2(math.cos(self.rotation - math.pi/2), math.sin(self.rotation - math.pi/2))
	local spawnPos = self.pos:copy() + 10 * dir

	return Bullet(spawnPos, self.rotation - math.pi/2, vec2(3, 3), 400, BulletType.PlayerBullet, {
        size_multiplier = self:get_bullet_scale(),
        portal_warp = self:can_bullet_boundary_warp(),
    })
end

---@param other Entity
function Player:onCollide(other)
    Entity.onCollide(self, other)
end

function Player:explode()
    local damageable = self:get_component("damageable")
    if damageable then
        damageable:change_health(self, -1)
    else
	    self.health = self.health - 1
    end
	love.audio.play(Sfx_big_explosion)
	self.world:clear_all_enemies()
	self.world:clear_all_enemy_bullets()
end

---@param dmg integer
function Player:takeDamage(dmg)
    local damageable = self:get_component("damageable")
    if damageable then
        return damageable:apply_damage(self, dmg)
    end
	self.health = self.health - dmg
    return true
end

function Player:get_upgrade_level(id)
    return self.upgradeLevels[id] or 0
end

function Player:increment_upgrade_level(id)
    local nextLevel = self:get_upgrade_level(id) + 1
    self.upgradeLevels[id] = nextLevel
    return nextLevel
end

function Player:get_move_speed(baseSpeed)
    local speed = baseSpeed or self.baseMoveSpeed
    local multiplier = self.upgrades.move_speed_multiplier or 1.0
    if self.boundaryBoostRemaining > 0 then
        multiplier = multiplier * (self.upgrades.boundary_boost_move_multiplier or 1.0)
    end
    return speed * multiplier
end

function Player:get_fire_rate_multiplier()
    local multiplier = self.upgrades.fire_rate_multiplier or 1.0
    if self.boundaryBoostRemaining > 0 then
        multiplier = multiplier * (self.upgrades.boundary_boost_fire_multiplier or 1.0)
    end
    return multiplier
end

function Player:get_auto_fire_cooldown(baseCooldown)
    local cooldown = baseCooldown or self.baseFireCooldown
    return cooldown / self:get_fire_rate_multiplier()
end

function Player:get_bullet_scale()
    return self.upgrades.bullet_scale or 1.0
end

function Player:can_bullet_boundary_warp()
    return self.upgrades.bullet_boundary_warp_enabled == true
end

function Player:activate_boundary_boost()
    if not self.upgrades.boundary_boost_enabled then
        return false
    end

    self.boundaryBoostRemaining = self.upgrades.boundary_boost_duration or 0
    return self.boundaryBoostRemaining > 0
end

function Player:on_boundary_crossed()
    if self:activate_boundary_boost() then
        love.audio.play(Sfx_power_up)
    end
end
