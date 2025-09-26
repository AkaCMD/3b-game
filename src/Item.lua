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
end

function Item:update(dt)
end

function Item:draw()
    if self.type == ItemType.Heart then
        local img = Assets.images.heart
        love.graphics.draw(img, self.pos.x, self.pos.y, 0, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
    end
end

function Item:onCollide()
end