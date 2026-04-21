local AutoFire = require("src.components.auto_fire")
local Damageable = require("src.components.damageable")
local Invulnerability = require("src.components.invulnerability")
local KeyboardMove = require("src.components.keyboard_move")
local LookAtCursor = require("src.components.look_at_cursor")

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
    self:set_tag("player")

    self:add_component("look_at_cursor", LookAtCursor())
    self:add_component("keyboard_move", KeyboardMove(200))
    self:add_component("weapon", AutoFire({
        cooldown = 0.15,
        should_fire = function()
            return love.mouse.isDown(1)
        end,
        create_projectile = function(entity)
            return entity:shoot()
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

	return Bullet(spawnPos, self.rotation - math.pi/2, vec2(3, 3), 400, BulletType.PlayerBullet)
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
