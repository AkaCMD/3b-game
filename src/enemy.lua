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

	self.shootCooldown = 0.3
	self.lastShotTime = 0
end

function Enemy:update(dt, level)
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

	if level then
        self.pos = level:wrapPosition(self.pos)
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
	return Bullet:pooled(spawnPos, self.rotation, vec2(2, 2), 4, BulletType.EnemyBullet)
end

make_pooled(Enemy, 120)

-- Builder Pattern
Enemy.Builder = {}
Enemy.Builder.__index = Enemy.Builder

function Enemy.Builder:new()
    local builder = setmetatable({}, Enemy.Builder)
    builder.pos = vec2(0, 0)
    builder.scale = vec2(1, 1)
    builder.rotation = 0
    builder.hitbox = vec2(12, 12)
    builder.hasCollision = true
    builder.health = 1
    builder.colliderType = COLLIDER_TYPE.dynamic
    builder.speed = 10
    builder.shootCooldown = 0.3
    builder.lastShotTime = 0
    return builder
end

function Enemy.Builder:withPosition(x, y)
    self.pos = vec2(x, y)
    return self
end

function Enemy.Builder:withScale(sx, sy)
    self.scale = vec2(sx, sy)
    return self
end

function Enemy.Builder:withRotation(r)
    self.rotation = r
    return self
end

function Enemy.Builder:withHitbox(width, height)
    self.hitbox = vec2(width, height)
    return self
end

function Enemy.Builder:withCollision(flag)
    self.hasCollision = flag
    return self
end

function Enemy.Builder:withHealth(hp)
    self.health = hp
    return self
end

function Enemy.Builder:withColliderType(t)
    self.colliderType = t
    return self
end

function Enemy.Builder:withSpeed(speed)
    self.speed = speed
    return self
end

function Enemy.Builder:withShootCooldown(cd)
    self.shootCooldown = cd
    return self
end

function Enemy.Builder:withLastShotTime(time)
    self.lastShotTime = time
    return self
end

function Enemy.Builder:build()
    local enemy = Enemy:pooled(self.pos, self.rotation, self.scale, self.speed)

    enemy.hitbox = self.hitbox
    enemy.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
    enemy.hasCollision = self.hasCollision
    enemy.health = self.health
    enemy.colliderType = self.colliderType

    enemy.shootCooldown = self.shootCooldown
    enemy.lastShotTime = self.lastShotTime

    return enemy
end