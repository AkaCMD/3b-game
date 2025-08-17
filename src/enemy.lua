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
	self.tween = nil
end

---@param target Entity What they are chasing
function Enemy:update(dt, level, target)
	if target and target.pos then
		local dir = (target.pos - self.pos):normalise_inplace()
		local targetAngle = math.atan2(dir.y, dir.x)
		if not self.tween or self.tween:isDone() then
			self.tween = Flux.to(self, 0.5, { rotation = targetAngle })
				:ease("quadout")
		end

		local moveDir = vec2(math.cos(self.rotation), math.sin(self.rotation))
		self.pos:add_inplace(moveDir:scalar_mul_inplace(self.speed * dt))
	end
end

function Enemy:draw()
	local img = Assets.images.enemy
	love.graphics.draw(img, self.pos.x, self.pos.y, self.rotation + math.pi/2, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
end