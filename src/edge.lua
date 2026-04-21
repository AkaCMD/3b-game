local Geometry = require("src.geometry")

Edge = class({
	name = "Edge",
	extends = Entity,
	default_tostring = true
})

EdgeType = {Normal = 1, SpawnEnemy = 2, Portal = 3, Damagable = 4}

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
	---@type EnemySpawner[]
	self.enemySpawners = {}
    self:set_tag("edge")
	Geometry.apply_edge_geometry(self)

	if self.edgeType == EdgeType.SpawnEnemy then
		self:placeEnemySpawners(3)
	end
end

---@param num integer Number of enemy spawners in this edge
function Edge:placeEnemySpawners(num)
	---@type number
	local interval = self.length / num
	for i = 1, num do
		local x, y = Geometry.lerp_point(
			self.startPos.x,
			self.startPos.y,
			self.endPos.x,
			self.endPos.y,
			(interval*i - interval/2) / self.length
		)
		local pos = vec2(x, y)
		local en = EnemySpawner(pos)
		table.insert(self.enemySpawners, en)
		self:spawn(en)
	end
end

function Edge:update(dt, context)
    Entity.update(self, dt, context)
end

function Edge:draw()
	if self.edgeType == EdgeType.SpawnEnemy then
		love.graphics.setColor(PALETTE.red)
	elseif self.edgeType == EdgeType.Portal then
		love.graphics.setColor(PALETTE.green)
	elseif self.edgeType == EdgeType.Damagable then
		love.graphics.setColor(PALETTE.white)
	else
		love.graphics.setColor(PALETTE.white)
	end
	love.graphics.line(self.startPos.x, self.startPos.y, self.endPos.x, self.endPos.y)

	love.graphics.setColor(PALETTE.white)
end

---@param other Entity
function Edge:onCollide(other)
    Entity.onCollide(self, other)
    local isPlayer = other:is(Player)
    local isBullet = other:is(Bullet)

    if self.edgeType == EdgeType.Normal then
        if isPlayer then logger.info("Normal") end
        if isBullet then other:free() end
        return
    end

    if self.edgeType == EdgeType.SpawnEnemy then
        if isPlayer then logger.info("SpawnEnemy") end
        if isBullet then other:free() end
        return
    end

    if self.edgeType == EdgeType.Damagable then
        if isPlayer then logger.info("Damagable") end
        if isBullet then other:free() end
        return
    end

	if self.edgeType == EdgeType.Portal then
		if isPlayer then
			logger.info("Portal")
			self:teleport(other)
			love.audio.play(Sfx_portal)
            return
		end

		if isBullet then
			if other.bulletType == BulletType.PlayerBullet then
				self:teleport(other)
			else
				other:free()
			end
            return
		end
    end
end

function CreatePortalPair(startA, endA, startB, endB)
	local a = Edge(startA, endA, EdgeType.Portal)
	local b = Edge(startB, endB, EdgeType.Portal)
	a.targetPortal = b
	b.targetPortal = a
	return a, b
end

---@param e Entity	Player or Bullet
function Edge:teleport(e)
    if self.edgeType ~= EdgeType.Portal or not self.targetPortal then return end

    local x, y = Geometry.portal_exit(
		e.pos.x,
		e.pos.y,
		self.startPos.x,
		self.startPos.y,
		self.endPos.x,
		self.endPos.y,
		self.targetPortal.startPos.x,
		self.targetPortal.startPos.y,
		self.targetPortal.endPos.x,
		self.targetPortal.endPos.y,
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

	Geometry.apply_edge_geometry(self)

	if self.edgeType == EdgeType.SpawnEnemy then
		for _, en in ipairs(self.enemySpawners) do
			en.isValid = false
		end
		self.enemySpawners = {}
		self:placeEnemySpawners(3)
	end
end
