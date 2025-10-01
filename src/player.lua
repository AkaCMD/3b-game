Player = class({
	name = "Player",
	extends = Entity,
	default_tostring = true
})

function Player:new(pos, scale)
	---@class Player: Entity
	self:super(pos, scale)
	self.lastPos = self.pos:copy()
	self.hitbox = vec2(8, 8)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
	self.health = 6
	self.isInvincible = false
	self.invincibleTimer = nil
end

function Player:update(dt, level)
	if self.invincibleTimer then
		self.invincibleTimer:update(dt)
	end
	self.lastPos = self.pos:copy()
	Entity:update(dt)

    self:lookAtCursor()

	local dir = vec2(0, 0)
    if love.keyboard.isDown("a") then dir.x = dir.x - 1 end
    if love.keyboard.isDown("d") then dir.x = dir.x + 1 end
    if love.keyboard.isDown("w") then dir.y = dir.y - 1 end
    if love.keyboard.isDown("s") then dir.y = dir.y + 1 end

    if dir:length_squared() > 0 then
        dir:normalise_inplace()
        self.pos:fused_multiply_add_inplace(dir, 200 * dt)
    end
end

function Player:keypressed(key)
	if key == "space" then
		-- Explode!
		self:explode()
	end
end

function Player:draw()
	Entity:draw()
	local img = Assets.images.fighter
	if self.lastPos.x > self.pos.x then
		love.graphics.draw(img, self.pos.x, self.pos.y, math.rad(-10) + self.rotation, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
	elseif self.lastPos.x < self.pos.x then
		love.graphics.draw(img, self.pos.x, self.pos.y, math.rad(10) + self.rotation, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
	else
		love.graphics.draw(img, self.pos.x, self.pos.y, self.rotation, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
	end
end

function Player:lookAtCursor()
    local mouseX, mouseY = love.mouse.getPosition()
    self.rotation = math.atan2(mouseY - self.pos.y, mouseX - self.pos.x) + math.pi/2
end

function Player:shoot()
	love.audio.play(Sfx_small_hit)
	local dir = vec2(math.cos(self.rotation - math.pi/2), math.sin(self.rotation - math.pi/2))
	local spawnPos = self.pos:copy() + 10 * dir

	return Bullet(spawnPos, self.rotation - math.pi/2, vec2(3, 3), 400, BulletType.PlayerBullet)
end

---@param other Entity
function Player:onCollide(other)
	if other:is(Enemy) or (other:is(Bullet) and other.bulletType == BulletType.EnemyBullet) then
		if self.isInvincible then return end
		self:takeDamage(1)
		other:free()
	end
end

function Player:explode()
	self.health = self.health - 1
	love.audio.play(Sfx_big_explosion)
	World:clear_all_enemies()
	World:clear_all_enemy_bullets()
end

---@param dmg integer
function Player:takeDamage(dmg)
	-- Player become invincible for second after getting hurt 
	self.health = self.health - dmg
	self.invincibleTimer = Batteries.timer(
		1,
		function () self.isInvincible = true end,
		function () self.isInvincible = false end
	)
	bus:publish("player_take_damage")
	love.audio.play(Sfx_hurt)
end