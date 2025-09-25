LevelEvent = {
    EdgeRandomize = 1,
    SizeChange = 2,
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
    self.rotationSpeed = 0.8
    self.eventHandlers = {}
    self.eventTimer = Batteries.timer(
        30.0,
        nil,
        function(_, timer)
            self:randomEvent()
            timer:reset()
        end
    )
    self.edgeSlots = {}

    self:initEdges()

    self:registerDefaultHandlers()
end

function Level:initEdges()
    local corners = {
        vec2:pooled(self.center.x - self.hs.x, self.center.y - self.hs.y),
        vec2:pooled(self.center.x + self.hs.x, self.center.y - self.hs.y),
        vec2:pooled(self.center.x + self.hs.x, self.center.y + self.hs.y),
        vec2:pooled(self.center.x - self.hs.x, self.center.y + self.hs.y)
    }
    -- add fucking edges
    local portalTop, portalBottom = CreatePortalPair(corners[1], corners[2], corners[3], corners[4])
    -- add edges in clockwise
    table.insert(self.edgeSlots, 1, portalTop)
    table.insert(self.edgeSlots, 2, Edge(corners[2], corners[3], EdgeType.SpawnEnemy))
    table.insert(self.edgeSlots, 3, portalBottom)
    table.insert(self.edgeSlots, 4, Edge(corners[4], corners[1], EdgeType.Normal))
	for _, en in ipairs(self.edgeSlots) do
        World:add_entity(en)
    end
end

function Level:on(event, handler)
    if not self.eventHandlers[event] then
        self.eventHandlers[event] = {}
    end
    table.insert(self.eventHandlers[event], handler)
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

function Level:draw()
end

function Level:update(dt)
    self.eventTimer:update(dt)
	if self.isRotating then
		self.rotation = self.rotation + dt * self.rotationSpeed
	end
end

function Level:registerDefaultHandlers()
    self:on(LevelEvent.EdgeRandomize, function()
        self:randomizeEdges()
    end)

    self:on(LevelEvent.SizeChange, function(data)
        
    end)
end

function Level:randomEvent()
    local randomEvent = LevelEvent[math.random(1, #LevelEvent)]
    if randomEvent == LevelEvent.EdgeRandomize then
        
    elseif randomEvent == LevelEvent.SizeChange then
        
    end
end
