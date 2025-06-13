Bullet = class({
	name = "Bullet",
	extends = Entity,
	default_tostring = true
})

function Bullet:new(pos, scale)
	self:super(pos, scale)
	self.speed = 100
	self.hitbox = vec2(4, 4)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
	self,liveTimer = 0
end

function Bullet:update(dt)

	if self.liveTimer == 1 then
		self:free()
	end
end