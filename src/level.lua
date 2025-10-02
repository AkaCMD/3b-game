LevelEvent = {
    EdgeRandomize = 1,
    Shrink = 2,
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
    self.eventTimer = Batteries.timer(
        30.0,
        nil,
        function(_, timer)
            self:resetLevelScale()
            BloodBatch:clear()
            self:randomEvent()
            timer:reset()
            love.audio.play(Sfx_power_up)
        end
    )
    self.edgeSlots = {}

    self:initEdges()
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

function Level:randomEvent()
    ---@type integer
    local idx = math.random(#LevelEvent)
    if idx == LevelEvent.EdgeRandomize then
        logger.info("LevelEvent.EdgeRandomize")
        -- clear old edges
        self:clearEdges()
        self:randomizeEdges()
    elseif idx == LevelEvent.Shrink then
        logger.info("LevelEvent.SizeChange")
        self:shrinkLevel()
    end
end

function Level:randomizeEdges()
    local corners = {
        vec2:pooled(self.center.x - self.hs.x, self.center.y - self.hs.y),
        vec2:pooled(self.center.x + self.hs.x, self.center.y - self.hs.y),
        vec2:pooled(self.center.x + self.hs.x, self.center.y + self.hs.y),
        vec2:pooled(self.center.x - self.hs.x, self.center.y + self.hs.y)
    }
    self.edgeSlots = {}
    local needPortalPair = math.random() < 0.7

    local availablePositions = {1, 2, 3, 4}
    local portalPositions = {}

    if needPortalPair then
        for i = 1, 2 do
            local randomIndex = math.random(1, #availablePositions)
            local pos = availablePositions[randomIndex]
            table.insert(portalPositions, pos)
            table.remove(availablePositions, randomIndex)
        end

        local pos1 = portalPositions[1]
        local pos2 = portalPositions[2]
        local startCorner1 = corners[pos1]
        local endCorner1 = corners[pos1 % 4 + 1]
        local startCorner2 = corners[pos2]
        local endCorner2 = corners[pos2 % 4 + 1]

        local portalA, portalB = CreatePortalPair(startCorner1, endCorner1, startCorner2, endCorner2)

        self.edgeSlots[pos1] = portalA
        self.edgeSlots[pos2] = portalB
    end

    -- at least one enmey spawner edge
    local enemyPosition = availablePositions[math.random(1, #availablePositions)]
    local startCorner = corners[enemyPosition]
    local endCorner = corners[enemyPosition % 4 + 1]
    self.edgeSlots[enemyPosition] = Edge(startCorner, endCorner, EdgeType.SpawnEnemy)

    for i = #availablePositions, 1, -1 do
        if availablePositions[i] == enemyPosition then
            table.remove(availablePositions, i)
            break
        end
    end

    local edgeTypes = {EdgeType.Normal, EdgeType.SpawnEnemy}
    for _, pos in ipairs(availablePositions) do
        local startCorner = corners[pos]
        local endCorner = corners[pos % 4 + 1]
        local randomType = edgeTypes[math.random(1, #edgeTypes)]
        self.edgeSlots[pos] = Edge(startCorner, endCorner, randomType)
    end

    for _, edge in ipairs(self.edgeSlots) do
        if edge then
            World:add_entity(edge)
        end
    end
end

function Level:clearEdges()
    for i = #self.edgeSlots, 1, -1 do
        local en = self.edgeSlots[i]
        en.isValid = false
        for _, spawner in ipairs(en.enemySpawners) do
            spawner.isValid = false
        end
        table.remove(self.edgeSlots, i)
    end
end

ShrinkType = {
    X = 1,
    Y = 2,
    Both = 3,
}

function Level:shrinkLevel()
    local num = math.random(#ShrinkType)

    if num == ShrinkType.X then
        self.hs.x = self.hs.x * 0.5
    elseif num == ShrinkType.Y then
        self.hs.y = self.hs.y * 0.5
    elseif num == ShrinkType.Both then
        self.hs.x = self.hs.x * 0.5
        self.hs.y = self.hs.y * 0.5
    end

    local corners = {
        vec2(self.center.x - self.hs.x, self.center.y - self.hs.y),
        vec2(self.center.x + self.hs.x, self.center.y - self.hs.y),
        vec2(self.center.x + self.hs.x, self.center.y + self.hs.y),
        vec2(self.center.x - self.hs.x, self.center.y + self.hs.y)
    }

    self.edgeSlots[1].startPos, self.edgeSlots[1].endPos = corners[1], corners[2]
    self.edgeSlots[2].startPos, self.edgeSlots[2].endPos = corners[2], corners[3]
    self.edgeSlots[3].startPos, self.edgeSlots[3].endPos = corners[3], corners[4]
    self.edgeSlots[4].startPos, self.edgeSlots[4].endPos = corners[4], corners[1]

    for _, edge in ipairs(self.edgeSlots) do
        edge.pos = vec2((edge.startPos.x + edge.endPos.x) / 2, (edge.startPos.y + edge.endPos.y) / 2)
        edge.length = vec2.length(edge.endPos:vector_sub(edge.startPos))
        if math.abs(edge.endPos.x - edge.startPos.x) > math.abs(edge.endPos.y - edge.startPos.y) then
            edge.hitbox = vec2(edge.length, 5)
        else
            edge.hitbox = vec2(5, edge.length)
        end
        edge.hs = edge.hitbox:pooled_copy():scalar_mul_inplace(0.5)

        if edge.edgeType == EdgeType.SpawnEnemy then
            for _, en in ipairs(edge.enemySpawners) do
                en.isValid = false
            end
            edge.enemySpawners = {}
            edge:placeEnemySpawners(3)
        end
    end
end


function Level:resetLevelScale()
    self.hs = vec2(self.width / 2, self.height / 2)

    local corners = {
        vec2(self.center.x - self.hs.x, self.center.y - self.hs.y),
        vec2(self.center.x + self.hs.x, self.center.y - self.hs.y),
        vec2(self.center.x + self.hs.x, self.center.y + self.hs.y),
        vec2(self.center.x - self.hs.x, self.center.y + self.hs.y)
    }

    self.edgeSlots[1].startPos, self.edgeSlots[1].endPos = corners[1], corners[2]
    self.edgeSlots[2].startPos, self.edgeSlots[2].endPos = corners[2], corners[3]
    self.edgeSlots[3].startPos, self.edgeSlots[3].endPos = corners[3], corners[4]
    self.edgeSlots[4].startPos, self.edgeSlots[4].endPos = corners[4], corners[1]

    for _, edge in ipairs(self.edgeSlots) do
        edge.pos = vec2((edge.startPos.x + edge.endPos.x) / 2, (edge.startPos.y + edge.endPos.y) / 2)
        edge.length = vec2.length(edge.endPos:vector_sub(edge.startPos))

        if math.abs(edge.endPos.x - edge.startPos.x) > math.abs(edge.endPos.y - edge.startPos.y) then
            edge.hitbox = vec2(edge.length, 5)
        else
            edge.hitbox = vec2(5, edge.length)
        end
        edge.hs = edge.hitbox:pooled_copy():scalar_mul_inplace(0.5)

        if edge.edgeType == EdgeType.SpawnEnemy then
            for _, en in ipairs(edge.enemySpawners) do
                en.isValid = false
            end
            edge.enemySpawners = {}
            edge:placeEnemySpawners(3)
        end
    end
end