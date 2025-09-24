LevelEvent = {
    RotationStart = "rotation_start",
    RotationStop = "rotation_stop",
    EdgeRandomize = "edge_randomize",
    SizeChange = "size_change",
}

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
    self.eventHandlers = {}
    local corners = {
        vec2:pooled(self.center.x - self.hs.x, self.center.y - self.hs.y),
        vec2:pooled(self.center.x + self.hs.x, self.center.y - self.hs.y),
        vec2:pooled(self.center.x + self.hs.x, self.center.y + self.hs.y),
        vec2:pooled(self.center.x - self.hs.x, self.center.y + self.hs.y)
    }
    -- add fucking edges
    local portalTop, portalBottom = CreatePortalPair(corners[1], corners[2], corners[3], corners[4])
	World:add_entity(portalTop)
    World:add_entity(portalBottom)
    World:add_entity(Edge(corners[2], corners[3], EdgeType.SpawnEnemy))
	-- World:add_entity(Edge(corners[3], corners[4], EdgeType.Damagable))
    World:add_entity(Edge(corners[4], corners[1], EdgeType.Normal))

    self:registerDefaultHandlers()
end

function Level:on(event, handler)
    if not self.eventHandler[event] then
        self.eventHandler[event] = {}
    end
    table.insert(self.eventHandler[event], handler)
end

function Level:trigger(event, data)
    local handlers = self.eventHandlers[event]
    if handlers then
        for _, handler in ipairs(handlers) do
            handler(data)
        end
    end
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
end

function Level:update(dt)
	if self.isRotating then
		self.rotation = self.rotation + dt * 0.8
	end
end

function Level:registerDefaultHandlers()
    self:on(LevelEvent.RotationStart, function(data)
        self.isRotating = true
        self.rotationSpeed = data and data.speed or 0.8
        print("Level rotation started with speed: " .. self.rotationSpeed)
    end)

    self:on(LevelEvent.RotationStop, function(data)
        self.isRotating = false
        print("Level rotation stopped")
    end)

    self:on(LevelEvent.EdgeRandomize, function(data)
        self:randomizeEdges()
        print("Edges randomized")
    end)

    self:on(LevelEvent.SizeChange, function(data)
        if data and data.width and data.height then
            self:resize(data.width, data.height)
            print("Level resized to: " .. data.width .. "x" .. data.height)
        end
    end)
end
