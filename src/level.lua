Level = class({
	name = "Level",
	default_tostring = true
})

function Level:new(center, width, height, rotation, isRotating)
	self.center = center or vec2.new(360, 360)
	self.width = width or 480
	self.height = height or 480
	self.hs = vec2(width / 2, height / 2)
	self.rotation = rotation or 0
	self.isRotating = isRotating or false
end

function Level:containsPoint(point)
    local rel_point = point - self.center
    if self.rotation ~= 0 then
        local cos_r = math.cos(-self.rotation)
        local sin_r = math.sin(-self.rotation)
        local x = rel_point.x * cos_r - rel_point.y * sin_r
        local y = rel_point.x * sin_r + rel_point.y * cos_r
        rel_point.x, rel_point.y = x, y
    end
    local result = intersect.aabb_point_overlap(vec2(0, 0), self.hs, rel_point)
    return result
end

function Level:wrapPosition(pos)
    if self:containsPoint(pos) then
        return pos
    end
    local rel_pos = pos - self.center

    -- Transform position to level's coordinate system
    if self.rotation ~= 0 then
        local cos_r = math.cos(-self.rotation)
        local sin_r = math.sin(-self.rotation)
        local x = rel_pos.x * cos_r - rel_pos.y * sin_r
        local y = rel_pos.x * sin_r + rel_pos.y * cos_r
        rel_pos.x, rel_pos.y = x, y
    end

    -- Wrap in local coordinates
    local wrapped = rel_pos
    if wrapped.x <= -self.hs.x then
        wrapped.x = wrapped.x + self.width
    elseif wrapped.x >= self.hs.x then
        wrapped.x = wrapped.x - self.width
    end
    if wrapped.y <= -self.hs.y then
        wrapped.y = wrapped.y + self.height
    elseif wrapped.y >= self.hs.y then
        wrapped.y = wrapped.y - self.height
    end

    -- Transform back to world coordinates
    if self.rotation ~= 0 then
        local cos_r = math.cos(self.rotation)
        local sin_r = math.sin(self.rotation)
        local x = wrapped.x * cos_r - wrapped.y * sin_r
        local y = wrapped.x * sin_r + wrapped.y * cos_r
        wrapped.x, wrapped.y = x, y
    end
    wrapped = wrapped + self.center
    return wrapped
end

function Level:draw()
	love.graphics.setColor(0, 0.58, 0.47, 1)
    local corners = {
        vec2:pooled(self.center.x - self.hs.x, self.center.y - self.hs.y),
        vec2:pooled(self.center.x + self.hs.x, self.center.y - self.hs.y),
        vec2:pooled(self.center.x + self.hs.x, self.center.y + self.hs.y),
        vec2:pooled(self.center.x - self.hs.x, self.center.y + self.hs.y)
    }
    if self.rotation ~= 0 then
        local cos_r = math.cos(self.rotation)
        local sin_r = math.sin(self.rotation)
        for _, corner in ipairs(corners) do
            corner:vector_sub_inplace(self.center)
            local x = corner.x * cos_r - corner.y * sin_r
            local y = corner.x * sin_r + corner.y * cos_r
            corner.x, corner.y = x, y
            corner:vector_add_inplace(self.center)
        end
    end
    love.graphics.line(
        corners[1].x, corners[1].y,
        corners[2].x, corners[2].y,
        corners[3].x, corners[3].y,
        corners[4].x, corners[4].y,
        corners[1].x, corners[1].y
    )
    vec2.release(corners[1], corners[2], corners[3], corners[4])
    love.graphics.setColor(1, 1, 1, 1)
end

function Level:update(dt)
	if self.isRotating then
		self.rotation = self.rotation + dt * 0.8
	end
end
