local Geometry = require("src.geometry")

Edge = class({
	name = "Edge",
	extends = Entity,
	default_tostring = true
})

EdgeType = {Normal = 1, SpawnEnemy = 2, Portal = 3, Damagable = 4}

local EDGE_DRAW_COLORS = {
    [EdgeType.Normal] = PALETTE.white,
    [EdgeType.SpawnEnemy] = PALETTE.red,
    [EdgeType.Portal] = PALETTE.green,
    [EdgeType.Damagable] = PALETTE.white,
}

local EDGE_LABELS = {
    [EdgeType.Normal] = "Normal",
    [EdgeType.SpawnEnemy] = "SpawnEnemy",
    [EdgeType.Portal] = "Portal",
    [EdgeType.Damagable] = "Damagable",
}

---@class Edge
---@param start vec2
---@param finish vec2
---@param edgeTypeIndex integer
function Edge:new(start, finish, edgeTypeIndex)
	---@class Edge:Entity
	self:super(vec2((start.x + finish.x) / 2, (start.y + finish.y) / 2), vec2(1, 1), COLLIDER_TYPE.static)
	self.startPos = start
	self.endPos = finish
	self.edgeType = edgeTypeIndex
	self.scaleFactor = 1.0
    self.spawnerCount = 3
	self.enemySpawners = {}
    self.portalTarget = nil
    self:set_tag("edge")
    self:refresh_geometry()
end

function Edge:on_added_to_world(world)
    Entity.on_added_to_world(self, world)
    if self.edgeType == EdgeType.SpawnEnemy then
        self:rebuild_enemy_spawners()
    end
end

function Edge:on_removed_from_world(world)
    self:clear_enemy_spawners()
    Entity.on_removed_from_world(self, world)
end

function Edge:refresh_geometry()
    Geometry.apply_edge_geometry(self)
    if self.edgeType == EdgeType.SpawnEnemy and self.world then
        self:rebuild_enemy_spawners()
    end
end

function Edge:get_enemy_spawners()
    return self.enemySpawners
end

function Edge:clear_enemy_spawners()
    for _, spawner in ipairs(self.enemySpawners) do
        if spawner.free then
            spawner:free()
        else
            spawner.isValid = false
        end
    end
    self.enemySpawners = {}
end

function Edge:rebuild_enemy_spawners()
    self:clear_enemy_spawners()

    if not self.world or self.length <= 0 then
        return
    end

    local interval = self.length / self.spawnerCount
    for i = 1, self.spawnerCount do
        local x, y = Geometry.lerp_point(
            self.startPos.x,
            self.startPos.y,
            self.endPos.x,
            self.endPos.y,
            (interval * i - interval / 2) / self.length
        )
        local spawner = EnemySpawner(vec2(x, y))
        spawner.parentEdge = self
        table.insert(self.enemySpawners, spawner)
        self:spawn(spawner)
    end
end

function Edge:set_portal_target(targetEdge)
    self.portalTarget = targetEdge
end

function Edge:update(dt, context)
    Entity.update(self, dt, context)
end

function Edge:get_label()
    return EDGE_LABELS[self.edgeType] or "Edge"
end

function Edge:draw()
    local color = EDGE_DRAW_COLORS[self.edgeType] or PALETTE.white
    love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
    love.graphics.line(self.startPos.x, self.startPos.y, self.endPos.x, self.endPos.y)
    love.graphics.setColor(PALETTE.white)
    Entity.draw(self)
end

function Edge:handle_block_collision(other)
    if other:has_tag("player") then
        logger.info(self:get_label())
        return
    end

    if other:has_tag("bullet") then
        other:free()
    end
end

function Edge:handle_portal_collision(other)
    if other:has_tag("player") then
        logger.info("Portal")
        self:teleport(other)
        love.audio.play(Sfx_portal)
        return
    end

    if other:has_tag("player_bullet") then
        if other.canWarpEdges then
            self:teleport(other)
        else
            other:free()
        end
        return
    end

    if other:has_tag("enemy_bullet") then
        other:free()
    end
end

---@param other Entity
function Edge:onCollide(other)
    Entity.onCollide(self, other)
    if self.edgeType == EdgeType.Portal then
        self:handle_portal_collision(other)
        return
    end

    self:handle_block_collision(other)
end

function CreatePortalPair(startA, endA, startB, endB)
	local a = Edge(startA, endA, EdgeType.Portal)
	local b = Edge(startB, endB, EdgeType.Portal)
	a:set_portal_target(b)
	b:set_portal_target(a)
	return a, b
end

---@param e Entity	Player or Bullet
function Edge:teleport(e)
    if not self.portalTarget then
        return
    end

    local x, y = Geometry.portal_exit(
        e.pos.x,
        e.pos.y,
        self.startPos.x,
        self.startPos.y,
        self.endPos.x,
        self.endPos.y,
        self.portalTarget.startPos.x,
        self.portalTarget.startPos.y,
        self.portalTarget.endPos.x,
        self.portalTarget.endPos.y,
        8
    )
    e.pos = vec2(x, y)
end

---@param factor number
---@param center vec2
function Edge:scaler(factor)
	---@param p vec2
	local function scale_point(p)
		return vec2(
			self.pos.x + (p.x - self.pos.x) * factor,
			self.pos.y + (p.y - self.pos.y) * factor
		)
	end

	self.startPos = scale_point(self.startPos)
	self.endPos = scale_point(self.endPos)

	self:refresh_geometry()
end
