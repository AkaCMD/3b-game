local make_pooled = Batteries.make_pooled

Enemy = class({
	name = "Enemy",
	extends = Entity,
	default_tostring = true
})

function Enemy:new(pos, rot, scale, speed)
	---@class Enemy:Entity
	self:super(pos, scale)
	self.speed = speed or 10
	self.hitbox = vec2(12, 12)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
	self.rotation = rot or 0
	self.health = 1
end

function Enemy:update(dt, level)
	-- TODO: add cooldown
	World:add_entity(self:shoot())
	if player and player.pos then
		local dir = (player.pos - self.pos):normalise_inplace()
		local targetAngle = math.atan2(dir.y, dir.x)
		-- self.rotation = targetAngle
        local lerpSpeed = 3.0
        local angleDiff = (targetAngle - self.rotation + math.pi) % (2 * math.pi) - math.pi
        self.rotation = self.rotation + angleDiff * lerpSpeed * dt

		local moveDir = vec2(math.cos(self.rotation), math.sin(self.rotation))
		self.pos:add_inplace(moveDir:scalar_mul_inplace(self.speed * dt))
	end

	if level then
        self.pos = level:wrapPosition(self.pos)
    end
end

function Enemy:draw()
	local img = Assets.images.enemy
	love.graphics.draw(img, self.pos.x, self.pos.y, self.rotation + math.pi/2, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
end

function Enemy:onCollide(bullet)
    self.health = self.health - 1
    if self.health <= 0 then
		bus:publish("enemy_killed")
        self:free()
    end
    bullet:free()
end

function Enemy:free()
	--why i can't just write Entity:free() ?
	self.isValid = false
	Enemy.release(self)
end

function Enemy:shoot()
	local dir = vec2(math.cos(self.rotation - math.pi/2), math.sin(self.rotation - math.pi/2))
	local spawnPos = self.pos:copy() + 10 * dir
	-- TODO: enemy bullet
	return Bullet:pooled(spawnPos, self.rotation - math.pi/2, vec2(2, 2), 8)
end

make_pooled(Enemy, 120)