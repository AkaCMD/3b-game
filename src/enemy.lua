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

	self.shootCooldown = 0.5
	self.lastShotTime = 0

    -- avoid being stopped by edge after spawning
    self.hasCollision = false
    self.noCollisionTimer = Batteries.timer(
        1.5,
        nil,
        function () self.hasCollision = true end
    )
end

function Enemy:update(dt, level)
    self.noCollisionTimer:update(dt)
	-- Shoot cooldown
	self.lastShotTime = self.lastShotTime + dt
	if self.lastShotTime >= self.shootCooldown then
		World:add_entity(self:shoot())
		self.lastShotTime = 0
	end

	if player and player.pos then
		local dir = (player.pos - self.pos):normalise_inplace()
		local targetAngle = math.atan2(dir.y, dir.x)
        local lerpSpeed = 3.0
        local angleDiff = (targetAngle - self.rotation + math.pi) % (2 * math.pi) - math.pi
        self.rotation = self.rotation + angleDiff * lerpSpeed * dt

		local moveDir = vec2(math.cos(self.rotation), math.sin(self.rotation))
		self.pos:add_inplace(moveDir:scalar_mul_inplace(self.speed * dt))
	end
end

function Enemy:draw()
	local img = Assets.images.enemy
	love.graphics.draw(img, self.pos.x, self.pos.y, self.rotation + math.pi/2, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
end

---@param other Entity
function Enemy:onCollide(other)
	if other:is(Bullet) and other.bulletType == BulletType.PlayerBullet then
		self.health = self.health - 1
    	if self.health <= 0 then
			bus:publish("enemy_killed")

			local dropItemChance = 0.1
			if math.random() < dropItemChance then
				World:add_entity(Item(self.pos:copy(), vec2(1, 1), ItemType.Heart))
			end

        	self:free()
    	end
    	other:free()
	end
end

function Enemy:free()
	--why i can't just write Entity:free() ?
	self.isValid = false
	Enemy.release(self)
end

function Enemy:shoot()
	local dir = vec2(math.cos(self.rotation), math.sin(self.rotation))
	local spawnPos = self.pos:copy() + 10 * dir
	return Bullet(spawnPos, self.rotation, vec2(2, 2), 240, BulletType.EnemyBullet)
end

make_pooled(Enemy, 120)