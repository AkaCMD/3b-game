Enemy = class({
	name = "Enemy",
	extends = Entity,
	default_tostring = true
})

---@class Enemy:Entity
---@field speed number
function Enemy:new(pos, rot, scale, speed)
	self:super(pos, scale)
	self.speed = speed
	self.hitbox = vec2(8, 8)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
	self.rotation = rot
	self.health = 4
end

function Enemy:update(dt, level)

end

function Enemy:draw()
	local img = assets.images.enemy
	love.graphics.draw(img, self.pos.x, self.pos.y, self.rotation + math.pi/2, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
end