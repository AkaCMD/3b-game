Entity = class({
	name = "Entity",
	default_tostring = true
})

function Entity:new(pos, scale)
	self.pos = pos or vec2(0, 0)
	self.rotation = 0
	self.scale = scale or vec2(1, 1)
	self.hitbox = vec2(10, 10)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
	self.hasCollision = true
	self.isValid = true
end

function Entity:update(dt)
end

function Entity:draw()
end

function Entity:overlaps(other)
	if not self.hasCollision or not other.hasCollision then
		return false
	end
	return intersect.aabb_aabb_overlap(self.pos, self.hs, other.pos, other.hs)
end

function Entity:collide(other, into)
	if not self.hasCollision or not other.hasCollision then
        return false
    end
	return intersect.aabb_aabb_collide(self.pos, self.hs, other.pos, other.hs, into)
end

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

    love.graphics.setColor(1, 0, 0, 1) -- Red outline
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
    love.graphics.setColor(1, 1, 1, 1)
end

function Entity:free()
	self.isValid = false
end