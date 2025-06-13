Bullet = class({
	name = "Bullet",
	extends = Entity,
	default_tostring = true
})

function Bullet:new(pos, rot, scale, speed)
	self:super(pos, scale)
	self.speed = speed
	self.hitbox = vec2(4, 4)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
	self.liveTimer = 0
	self.rotation = rot
end

function Bullet:update(dt, level)
	self.pos.x = self.pos.x + math.cos(self.rotation) * self.speed
	self.pos.y = self.pos.y + math.sin(self.rotation) * self.speed

	if self.liveTimer >= 1 then
		self:free()
	end
	self.liveTimer = self.liveTimer + dt

    if not level:containsPoint(self.pos) then
        self:free()
    end
    -- self.pos = level:wrapPosition(self.pos)
end

function Bullet:draw()
	img = assets.images.bullet
	love.graphics.draw(img, self.pos.x, self.pos.y, self.rotation + math.pi/2, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
end