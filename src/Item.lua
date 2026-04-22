local CollisionAction = require("src.components.collision_action")
local FloatY = require("src.components.float_y")

Item = class({
    name = "Item",
    extends = Entity,
    default_tostring = true
})

ItemType = {Heart = 1}

---@param pos vec2
---@param scale vec2
---@param type integer
function Item:new(pos, scale, type)
    ---@class Item : Entity
    self:super(pos, scale, COLLIDER_TYPE.trigger)
    self.pos = pos
    self.type = type
    self.hitbox = vec2(20, 20)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
    self:set_tag("item")
    self:add_component("float_y", FloatY(5, 1.5))
    self:add_component("pickup", CollisionAction({
        targetTags = { "player" },
        consume_self = true,
        action = function(entity, other)
            local damageable = other:get_component("damageable")
            if damageable then
                damageable:change_health(other, 1)
            else
                other.health = other.health + 1
            end
            love.audio.play(Sfx_pickup)
            return true
        end,
    }))
end

function Item:update(dt, context)
    Entity.update(self, dt, context)
end

function Item:draw()
    if self.type == ItemType.Heart then
        local img = Assets.images.heart
        love.graphics.draw(img, self.pos.x, self.pos.y, 0, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
    end
end

function Item:onCollide(other)
    Entity.onCollide(self, other)
end
