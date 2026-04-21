local Geometry = require("src.geometry")
local EdgeBlockContact = require("src.components.edge_block_contact")
local EdgeDrawLine = require("src.components.edge_draw_line")
local EdgeEnemySpawners = require("src.components.edge_enemy_spawners")
local EdgePortal = require("src.components.edge_portal")

Edge = class({
	name = "Edge",
	extends = Entity,
	default_tostring = true
})

EdgeType = {Normal = 1, SpawnEnemy = 2, Portal = 3, Damagable = 4}

local EDGE_SETUPS = {
    [EdgeType.Normal] = function(edge)
        edge:add_component("draw_line", EdgeDrawLine(PALETTE.white))
        edge:add_component("contact_rule", EdgeBlockContact({ label = "Normal" }))
    end,
    [EdgeType.SpawnEnemy] = function(edge)
        edge:add_component("draw_line", EdgeDrawLine(PALETTE.red))
        edge:add_component("contact_rule", EdgeBlockContact({ label = "SpawnEnemy" }))
        edge:add_component("enemy_spawners", EdgeEnemySpawners(3))
    end,
    [EdgeType.Portal] = function(edge)
        edge:add_component("draw_line", EdgeDrawLine(PALETTE.green))
        edge:add_component("portal", EdgePortal())
    end,
    [EdgeType.Damagable] = function(edge)
        edge:add_component("draw_line", EdgeDrawLine(PALETTE.white))
        edge:add_component("contact_rule", EdgeBlockContact({ label = "Damagable" }))
    end,
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
	self.enemySpawners = {}
    self:set_tag("edge")
    self:refresh_geometry()
    self:apply_type_setup(edgeTypeIndex)
end

function Edge:apply_type_setup(edgeTypeIndex)
    local setup = EDGE_SETUPS[edgeTypeIndex]
    if setup then
        setup(self)
    end
end

function Edge:refresh_geometry()
    Geometry.apply_edge_geometry(self)
    for _, component in ipairs(self.components) do
        if component.on_geometry_changed then
            component:on_geometry_changed(self)
        end
    end
end

function Edge:get_enemy_spawners()
    local component = self:get_component("enemy_spawners")
    return component and component:get_spawners() or self.enemySpawners
end

function Edge:clear_enemy_spawners()
    local component = self:get_component("enemy_spawners")
    if component then
        component:clear(self)
    end
end

function Edge:set_portal_target(targetEdge)
    local portal = self:get_component("portal")
    if portal then
        portal:set_target(targetEdge)
    end
end

function Edge:update(dt, context)
    Entity.update(self, dt, context)
end

function Edge:draw()
    Entity.draw(self)
end

---@param other Entity
function Edge:onCollide(other)
    Entity.onCollide(self, other)
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
    local portal = self:get_component("portal")
    if portal then
        portal:teleport(self, e)
    end
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
