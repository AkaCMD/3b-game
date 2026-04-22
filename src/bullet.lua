local BoundsCleanup = require("src.components.bounds_cleanup")
local CollisionAction = require("src.components.collision_action")
local MoveForward = require("src.components.move_forward")
local make_pooled = Batteries.make_pooled

Bullet = class({
	name = "Bullet",
	extends = Entity,
	default_tostring = true
})

BulletType = { PlayerBullet = 1, EnemyBullet = 2}

---@param pos vec2
---@param rot number
---@param scale vec2
---@param speed number
---@param type integer Type of the bullet
---@param mods table|nil
function Bullet:new(pos, rot, scale, speed, type, mods)
	---@class Bullet: Entity
    mods = mods or {}
	self:super(pos, scale, COLLIDER_TYPE.trigger)
	self.speed = speed or 480
	self.rotation = rot
	self.bulletType = type or BulletType.PlayerBullet
    self.canWarpEdges = mods.portal_warp == true

    local bulletSizeMultiplier = mods.size_multiplier or 1.0
    if self.bulletType == BulletType.PlayerBullet then
        self.scale.x = self.scale.x * bulletSizeMultiplier
        self.scale.y = self.scale.y * bulletSizeMultiplier
        self.hitbox = vec2(4 * bulletSizeMultiplier, 4 * bulletSizeMultiplier)
    else
        self.hitbox = vec2(4, 4)
    end
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
    self:set_tag("bullet")
    if self.bulletType == BulletType.PlayerBullet then
        self:set_tag("player_bullet")
    elseif self.bulletType == BulletType.EnemyBullet then
        self:set_tag("enemy_bullet")
    end

    self:add_component("move_forward", MoveForward())
    self:add_component("bounds_cleanup", BoundsCleanup({ delay = 1.5 }))
    if self.bulletType == BulletType.PlayerBullet then
        self:add_component("collision_action", CollisionAction({
            targetTags = { "enemy" },
            consume_self = true,
            action = function(entity, other)
                if other.receive_bullet_hit then
                    return other:receive_bullet_hit(entity, 1)
                end

                local damageable = other.get_component and other:get_component("damageable")
                if not damageable then
                    return false
                end

                return damageable:apply_damage(other, 1, entity)
            end,
        }))
    elseif self.bulletType == BulletType.EnemyBullet then
        self:add_component("collision_action", CollisionAction({
            targetTags = { "player" },
            consume_self = true,
            action = function(entity, other)
                local damageable = other.get_component and other:get_component("damageable")
                if not damageable then
                    return false
                end

                return damageable:apply_damage(other, 1, entity)
            end,
        }))
    end
end

function Bullet:update(dt, context)
	Entity.update(self, dt, context)
end

function Bullet:draw()
	local img = Assets.images.bullet
	if self.bulletType == BulletType.PlayerBullet then
		love.graphics.draw(img, self.pos.x, self.pos.y, self.rotation + math.pi/2, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
	elseif self.bulletType == BulletType.EnemyBullet then
		love.graphics.setColor(PALETTE.red)
		love.graphics.draw(img, self.pos.x, self.pos.y, self.rotation + math.pi/2, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
		love.graphics.setColor(PALETTE.white)
	end
end

function Bullet:free()
	self.isValid = false
	Bullet.release(self)
end


make_pooled(Bullet, 500)
