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
    self.time = 0
    self.baseY = self.pos.y
    self.hitbox = vec2(20, 20)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
end

function Item:update(dt)
    self.time = self.time + dt
    self.pos.y = sinwave(self.baseY, self.time, 5, 1.5)
end

function Item:draw()
    if self.type == ItemType.Heart then
        local img = Assets.images.heart
        love.graphics.draw(img, self.pos.x, self.pos.y, 0, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
    end
end

function Item:onCollide(other)
    if other:is(Player) then
        other.health = other.health + 1
        love.audio.play(Sfx_pickup)
        self.isValid = false
    end
end