vec2 = Batteries.vec2
Entity = class({
	name = "Entity",
	default_tostring = true
})

COLLIDER_TYPE = {
    dynamic = 0,
    static = 1,
    trigger = 2,
}

---Make an entity
---@param pos vec2
---@param scale vec2
---@class Entity
---@field rotation number
---@field pos vec2
---@field scale vec2
---@field hitbox vec2
---@field hs vec2
---@field hasCollision boolean
---@field isValid boolean
---@field health integer
---@field colliderType integer
function Entity:new(pos, scale, collider_type)
    self.rotation = 0
	self.pos = pos or vec2(0, 0)
	self.scale = scale or vec2(1, 1)
	self.hitbox = vec2(10, 10)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
	self.hasCollision = true
	self.isValid = true
	self.health = 3
    self.colliderType = collider_type or COLLIDER_TYPE.dynamic
end

function Entity:update(dt)
end

function Entity:draw()
end

---@param other Entity
---@return boolean
function Entity:overlaps(other)
	if not self.hasCollision or not other.hasCollision then
		return false
	end
	return intersect.aabb_aabb_overlap(self.pos, self.hs, other.pos, other.hs)
end

---@param other Entity
---@param into vec2
---@return msv|false result
function Entity:collide(other, into)
	if not self.hasCollision or not other.hasCollision then
        return false
    end
	return intersect.aabb_aabb_collide(self.pos, self.hs, other.pos, other.hs, into)
end

---@param other Entity
---@param balance number
---@return msv|false msv
function Entity:resolveCollision(other, balance)
	if not self.hasCollision or not other.hasCollision then
		return false
	end
	balance = balance or 0.5
	local msv = self:collide(other)
	if msv then
		intersect.resolve_msv(self.pos, other.pos, msv, balance)
	end
	return msv
end

function Entity:moveTo(x, y)
    self.pos:set(x, y)
end

function Entity:drawHitbox()
	if not self.hasCollision then
		return
	end

    if self.colliderType == COLLIDER_TYPE.dynamic then
        love.graphics.setColor(1, 0, 0, 1)  -- red
    elseif self.colliderType == COLLIDER_TYPE.static then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.7)  -- blue
    elseif self.colliderType == COLLIDER_TYPE.trigger then
        love.graphics.setColor(1.0, 1.0, 0.2, 0.5)  -- yellow
    end
    local hs = self.hs:pooled_copy():vector_mul(self.scale)
    local corners = {
        vec2:pooled(self.pos.x - hs.x, self.pos.y - hs.y), -- Top-left
        vec2:pooled(self.pos.x + hs.x, self.pos.y - hs.y), -- Top-right
        vec2:pooled(self.pos.x + hs.x, self.pos.y + hs.y), -- Bottom-right
        vec2:pooled(self.pos.x - hs.x, self.pos.y + hs.y)  -- Bottom-left
    }
    if self.rotation ~= 0 then
        local cos_r = math.cos(self.rotation)
        local sin_r = math.sin(self.rotation)
        for _, corner in ipairs(corners) do
            corner:vector_sub_inplace(self.pos)
            local x = corner.x * cos_r - corner.y * sin_r
            local y = corner.x * sin_r + corner.y * cos_r
            corner.x, corner.y = x, y
            corner:vector_add_inplace(self.pos)
        end
    end
    love.graphics.line(
        corners[1].x, corners[1].y,
        corners[2].x, corners[2].y,
        corners[3].x, corners[3].y,
        corners[4].x, corners[4].y,
        corners[1].x, corners[1].y
    )
    vec2.release(hs, corners[1], corners[2], corners[3], corners[4])
    love.graphics.setColor(PALETTE.white)
end

function Entity:free()
	self.isValid = false
end

---@param other Entity
function Entity:onCollide(other)
end



-- Builder Pattern
Entity.Builder = {}
Entity.Builder.index = Entity.Builder

function Entity.Builder:new()
    return setmetatable({
        pos          = vec2(0, 0),
        scale        = vec2(1, 1),
        rotation     = 0,
        hitbox       = vec2(10, 10),
        hasCollision = true,
        isValid      = true,
        health       = 3,
        colliderType = COLLIDER_TYPE.dynamic,
    }, self)
end

function Entity.Builder:withPosition(x, y)
    self.properties.pos = vec2(x, y)
    return self
end

function Entity.Builder:withScale(sx, sy)
    self.properties.scale = vec2(sx, sy)
    return self
end

function Entity.Builder:withRotation(r)
    self.properties.rotation = r
    return self
end

function Entity.Builder:withHitbox(width, height)
    self.properties.hitbox = vec2(width, height)
    return self
end

---@param flag boolean
function Entity.Builder:setCollision(flag)
    self.hasCollision = flag
    return self
end

function Entity.Builder:setHealth(hp)
    self.health = hp
    return self
end

function Entity.Builder:setColliderType(t)
    self.colliderType = t
    return self
end

function Entity.Builder:build()
    local e = Entity(self.pos, self.scale, self.colliderType)

    e.rotation     = self.rotation
    e.hitbox       = self.hitbox
    e.hs           = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
    e.hasCollision = self.hasCollision
    e.isValid      = self.isValid
    e.health       = self.health
    return e
end