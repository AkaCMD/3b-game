local make_pooled = Batteries.make_pooled

Bullet = class({
	name = "Bullet",
	extends = Entity,
	default_tostring = true
})

BulletType = { PlayerBullet = 1, EnemyBullet = 2}

---@param pos vec2
---@param rot number
---@param scale vec2
---@param speed number
---@param type integer Type of the bullet
function Bullet:new(pos, rot, scale, speed, type)
	---@class Bullet: Entity
	self:super(pos, scale)
	self.speed = speed or 8
	self.hitbox = vec2(4, 4)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
	self.liveTimer = 0
	self.rotation = rot
	self.bulletType = type or BulletType.PlayerBullet
end

function Bullet:update(dt, level)
	self.pos.x = self.pos.x + math.cos(self.rotation) * self.speed
	self.pos.y = self.pos.y + math.sin(self.rotation) * self.speed

	if self.liveTimer >= 1.5 and not level:containsPoint(self.pos) then
		self:free()
	end
	self.liveTimer = self.liveTimer + dt

    if self.bulletType == BulletType.EnemyBullet and (not level:containsPoint(self.pos)) then
        self:free()
    end
    self.pos = level:wrapPosition(self.pos)
end

function Bullet:draw()
	local img = Assets.images.bullet
	if self.bulletType == BulletType.PlayerBullet then
		love.graphics.draw(img, self.pos.x, self.pos.y, self.rotation + math.pi/2, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
	elseif self.bulletType == BulletType.EnemyBullet then
		love.graphics.setColor(PALETTE.red)
		love.graphics.draw(img, self.pos.x, self.pos.y, self.rotation + math.pi/2, self.scale.x, self.scale.y, img:getWidth()/2, img:getHeight()/2)
		love.graphics.setColor(PALETTE.white)
	end
end

function Bullet:free()
	self.isValid = false
	Bullet.release(self)
end

make_pooled(Bullet, 500)