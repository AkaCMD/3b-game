require("src.Item")

local AutoFire = require("src.components.auto_fire")
local Damageable = require("src.components.damageable")
local HitTargets = require("src.components.hit_targets")
local TimedCollisionUnlock = require("src.components.timed_collision_unlock")
local TrackTarget = require("src.components.track_target")
local make_pooled = Batteries.make_pooled

Enemy = class({
	name = "Enemy",
	extends = Entity,
	default_tostring = true
})

function Enemy:new(pos, rot, scale, speed)
	---@class Enemy : Entity
	self:super(pos, scale)
	self.speed = speed or 10
	self.hitbox = vec2(12, 12)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
	self.rotation = rot or 0
	self.health = 1
    self:set_tag("enemy")

    self:add_component("collision_unlock", TimedCollisionUnlock(1))
    self:add_component("track_target", TrackTarget({
        speed = self.speed,
        rotateSpeed = 3,
        targetTag = "player",
    }))
    self:add_component("weapon", AutoFire({
        cooldown = 0.5,
        should_fire = function()
            return true
        end,
        create_projectile = function(entity)
            return entity:shoot()
        end,
    }))
    self:add_component("contact_damage", HitTargets({
        targetTags = { "player" },
        damage = 1,
        destroyOnHit = true,
    }))
    self:add_component("damageable", Damageable({
        health = 1,
        maxHealth = 1,
        on_death = function(entity)
            entity:emit("enemy_killed", { enemy = entity })

            local dropItemChance = 0.1
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

function Enemy:update(dt, context)
    Entity.update(self, dt, context)
end

function Enemy:draw()
	local img = Assets.images.enemy
	love.graphics.draw(img, self.pos.x, self.pos.y, self.rotation + math.pi/2, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
end

---@param other Entity
function Enemy:onCollide(other)
    Entity.onCollide(self, other)
end

function Enemy:free()
	self.isValid = false
	Enemy.release(self)
end

function Enemy:shoot()
	local dir = vec2(math.cos(self.rotation), math.sin(self.rotation))
	local spawnPos = self.pos:copy() + 10 * dir
	return Bullet(spawnPos, self.rotation, vec2(2, 2), 240, BulletType.EnemyBullet)
end

make_pooled(Enemy, 120)
