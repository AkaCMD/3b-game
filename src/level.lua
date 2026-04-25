local Geometry = require("src.geometry")
local LevelEdgeRules = require("src.level_edge_rules")

LevelEvent = {
    EdgeRandomize = "edge_randomize",
    Shrink = "shrink",
    ShapeShift = "shape_shift",
}

local LEVEL_EVENT_ORDER = {
    LevelEvent.EdgeRandomize,
    LevelEvent.Shrink,
    LevelEvent.ShapeShift,
}

ShrinkType = {
    X = "x",
    Y = "y",
    Both = "both",
}

local SHRINK_VARIANTS = {
    [ShrinkType.X] = {
        widthFactor = 0.7,
        heightFactor = 1.0,
        label = "边界左右收缩",
    },
    [ShrinkType.Y] = {
        widthFactor = 1.0,
        heightFactor = 0.7,
        label = "边界上下收缩",
    },
    [ShrinkType.Both] = {
        widthFactor = 0.72,
        heightFactor = 0.72,
        label = "边界整体收缩",
    },
}

local SHRINK_TYPE_ORDER = {
    ShrinkType.X,
    ShrinkType.Y,
    ShrinkType.Both,
}

BoundaryShapeType = {
    Wide = "wide",
    Tall = "tall",
    WideArena = "wide_arena",
    TallArena = "tall_arena",
}

local BOUNDARY_SHAPE_VARIANTS = {
    [BoundaryShapeType.Wide] = {
        widthFactor = 1.3,
        heightFactor = 0.82,
        label = "边界横向拉伸",
    },
    [BoundaryShapeType.Tall] = {
        widthFactor = 0.82,
        heightFactor = 1.3,
        label = "边界纵向拉伸",
    },
    [BoundaryShapeType.WideArena] = {
        widthFactor = 1.4,
        heightFactor = 0.72,
        label = "边界变成长走廊",
    },
    [BoundaryShapeType.TallArena] = {
        widthFactor = 0.72,
        heightFactor = 1.4,
        label = "边界变成竖走廊",
    },
}

local BOUNDARY_SHAPE_ORDER = {
    BoundaryShapeType.Wide,
    BoundaryShapeType.Tall,
    BoundaryShapeType.WideArena,
    BoundaryShapeType.TallArena,
}

---@param list table
---@param random_int? fun(min: integer, max: integer): integer
---@return any
local function choose_random(list, random_int)
    random_int = random_int or math.random
    return list[random_int(1, #list)]
end

Level = class({
	name = "Level",
	default_tostring = true
})

---@param center? vec2
---@param width? number
---@param height? number
---@param rotation? number
---@param isRotating? boolean
function Level:new(center, width, height, rotation, isRotating)
	self.center = center or vec2.new(360, 360)
	self.width = width or 480
	self.height = height or 480
	self.rotation = rotation or 0
	self.isRotating = isRotating or false
	self.rotationSpeed = 0
	self.hs = vec2(self.width / 2, self.height / 2)
    self.eventTimer = Batteries.timer(
        30.0,
        nil,
        ---@param _ any
        ---@param timer table
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

---@param offset? number
---@return vec2[]
function Level:getCorners(offset)
    local raw_corners = Geometry.rectangle_corners(
        self.center.x,
        self.center.y,
        self.hs.x,
        self.hs.y,
        offset
    )

    local corners = {}
    for i, point in ipairs(raw_corners) do
        corners[i] = vec2(point.x, point.y)
    end
    return corners
end

---@param corners vec2[]
function Level:setEdgesFromCorners(corners)
    self.edgeSlots[1].startPos, self.edgeSlots[1].endPos = corners[1], corners[2]
    self.edgeSlots[2].startPos, self.edgeSlots[2].endPos = corners[2], corners[3]
    self.edgeSlots[3].startPos, self.edgeSlots[3].endPos = corners[3], corners[4]
    self.edgeSlots[4].startPos, self.edgeSlots[4].endPos = corners[4], corners[1]
    self:syncEdgeGeometry()
end

function Level:syncEdgeGeometry()
    for _, edge in ipairs(self.edgeSlots) do
        edge.levelCenter = self.center
        edge:refresh_geometry()
    end
end

function Level:initEdges()
    local corners = self:getCorners()
    -- add fucking edges
    local portalTop, portalBottom = CreatePortalPair(corners[1], corners[2], corners[3], corners[4])
    -- add edges in clockwise
    table.insert(self.edgeSlots, 1, portalTop)
    table.insert(self.edgeSlots, 2, Edge(corners[2], corners[3], EdgeType.SpawnEnemy))
    table.insert(self.edgeSlots, 3, portalBottom)
    table.insert(self.edgeSlots, 4, Edge(corners[4], corners[1], EdgeType.Normal))
	for _, en in ipairs(self.edgeSlots) do
        en.levelCenter = self.center
        World:add_entity(en)
    end
end

---@param point vec2
---@return boolean
function Level:containsPoint(point)
    local rel_point = point - self.center
    local result = intersect.aabb_point_overlap(vec2(0, 0), self.hs, rel_point)
    return result
end

function Level:draw()
    self:drawOutline()
end

---@param dt number
function Level:update(dt)
    self.eventTimer:update(dt)
	if self.isRotating then
		self.rotation = self.rotation + dt * self.rotationSpeed
	end
end

---@param widthFactor number
---@param heightFactor number
function Level:apply_boundary_factors(widthFactor, heightFactor)
    self.hs = vec2(
        (self.width / 2) * widthFactor,
        (self.height / 2) * heightFactor
    )
    self:setEdgesFromCorners(self:getCorners())
end

---@param text string
---@return string
function Level:announce_event(text)
    self.lastEventLabel = text
    return text
end

---@param random_int? fun(min: integer, max: integer): integer
---@param random_float? fun(): number
---@return string
function Level:randomEvent(random_int, random_float)
    local eventId = choose_random(LEVEL_EVENT_ORDER, random_int)
    if eventId == LevelEvent.EdgeRandomize then
        self:announce_event("边界事件：边缘规则重排")
        -- clear old edges
        self:clearEdges()
        self:randomizeEdges(random_int, random_float)
    elseif eventId == LevelEvent.Shrink then
        self:shrinkLevel(random_int)
    elseif eventId == LevelEvent.ShapeShift then
        self:shiftBoundaryShape(random_int)
    end
    return eventId
end

---@param random_int? fun(min: integer, max: integer): integer
---@param random_float? fun(): number
function Level:randomizeEdges(random_int, random_float)
    local corners = self:getCorners()
    self.edgeSlots = {}
    local layout = LevelEdgeRules.build_layout(random_int, random_float)
    local portal_pairs = {}

    for position, rule in pairs(layout) do
        local start_corner = corners[position]
        local end_corner = corners[position % 4 + 1]

        if rule.kind == LevelEdgeRules.EdgeKind.Portal then
            local target_position = rule.target
            local pair_key = ("%d:%d"):format(math.min(position, target_position), math.max(position, target_position))
            if not portal_pairs[pair_key] then
                local target_start = corners[target_position]
                local target_end = corners[target_position % 4 + 1]
                local portal_a, portal_b = CreatePortalPair(start_corner, end_corner, target_start, target_end)
                portal_pairs[pair_key] = true
                self.edgeSlots[position] = portal_a
                self.edgeSlots[target_position] = portal_b
            end
        elseif rule.kind == LevelEdgeRules.EdgeKind.SpawnEnemy then
            self.edgeSlots[position] = Edge(start_corner, end_corner, EdgeType.SpawnEnemy)
        else
            self.edgeSlots[position] = Edge(start_corner, end_corner, EdgeType.Normal)
        end
    end

    for _, edge in ipairs(self.edgeSlots) do
        if edge then
            edge.levelCenter = self.center
            World:add_entity(edge)
        end
    end
end

function Level:clearEdges()
    for i = #self.edgeSlots, 1, -1 do
        local en = self.edgeSlots[i]
        en:clear_enemy_spawners()
        en.isValid = false
        table.remove(self.edgeSlots, i)
    end
end

---@param random_int? fun(min: integer, max: integer): integer
---@return string
function Level:shrinkLevel(random_int)
    local shrinkType = choose_random(SHRINK_TYPE_ORDER, random_int)
    local variant = SHRINK_VARIANTS[shrinkType] or SHRINK_VARIANTS[ShrinkType.Both]
    self:announce_event(variant.label)
    self:apply_boundary_factors(variant.widthFactor, variant.heightFactor)
    return shrinkType
end

---@param random_int? fun(min: integer, max: integer): integer
---@return string
function Level:shiftBoundaryShape(random_int)
    local shapeType = choose_random(BOUNDARY_SHAPE_ORDER, random_int)
    local variant = BOUNDARY_SHAPE_VARIANTS[shapeType] or BOUNDARY_SHAPE_VARIANTS[BoundaryShapeType.Wide]
    self:announce_event(variant.label)
    self:apply_boundary_factors(variant.widthFactor, variant.heightFactor)
    return shapeType
end

function Level:resetLevelScale()
    self:apply_boundary_factors(1.0, 1.0)
end

function Level:drawOutline()
    local offset = 8
    love.graphics.setLineWidth(2)

    local raw_corners = Geometry.rectangle_corners(self.center.x, self.center.y, self.hs.x, self.hs.y, offset)

    love.graphics.polygon("line",
        raw_corners[1].x, raw_corners[1].y,
        raw_corners[2].x, raw_corners[2].y,
        raw_corners[3].x, raw_corners[3].y,
        raw_corners[4].x, raw_corners[4].y
    )
end
