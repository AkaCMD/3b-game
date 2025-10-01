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
	self.length = vec2.length(finish:vector_sub(start))
	self.edgeType = edgeTypeIndex
	self.scaleFactor = 1.0

	if math.abs(finish.x - start.x) > math.abs(finish.y - start.y) then
		self.hitbox = vec2(self.length, 5)
	else
		self.hitbox = vec2(5, self.length)
	end
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
	---@type EnemySpawner[]
	self.enemySpawners = {}

	if self.edgeType == EdgeType.SpawnEnemy then
		self:placeEnemySpawners(3)
	end
end

---@param num integer Number of enemy spawners in this edge
function Edge:placeEnemySpawners(num)
	---@type number
	local interval = self.length / num
	for i = 1, num do
		local pos = lerp_vec2(self.startPos, self.endPos, (interval*i - interval/2) / self.length)
		local en = EnemySpawner(pos)
		table.insert(self.enemySpawners, en)
		World:add_entity(en)
	end
end

function Edge:update(dt)
	if self.edgeType == EdgeType.SpawnEnemy then
		for _, spawner in ipairs(self.enemySpawners) do
            spawner:update(dt)
        end
	end
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
		end

		if isBullet then
			if other.bulletType == BulletType.PlayerBullet then
				self:teleport(other)
			else
				other:free()
			end
		end
    end

    if isPlayer or (isBullet and other.bulletType == BulletType.PlayerBullet) then
        self:teleport(other)
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

    local t = project_ratio_on_segment(e.pos, self.startPos, self.endPos)

    local dest = lerp_vec2(self.targetPortal.startPos, self.targetPortal.endPos, t)

    local dx = self.targetPortal.endPos.x - self.targetPortal.startPos.x
    local dy = self.targetPortal.endPos.y - self.targetPortal.startPos.y
    local len = math.sqrt(dx*dx + dy*dy)
    local nx, ny = -dy/len, dx/len
    e.pos = vec2(dest.x + nx*8, dest.y + ny*8)
end

function project_ratio_on_segment(p, a, b)
    local vx, vy = b.x - a.x, b.y - a.y
    local wx, wy = p.x - a.x, p.y - a.y
    local denom = vx*vx + vy*vy
    if denom == 0 then
        return 0
    end
    local t = (wx * vx + wy * vy) / denom
    return Mathx.clamp(t, 0, 1)
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

	-- update length and hitbox
	self.length = self.length * factor
    if math.abs(self.endPos.x - self.startPos.x) > math.abs(self.endPos.y - self.startPos.y) then
        self.hitbox = vec2(self.length, 5)
    else
        self.hitbox = vec2(5, self.length)
    end

	if self.edgeType == EdgeType.SpawnEnemy then
		for _, en in ipairs(self.enemySpawners) do
			en.isValid = false
		end
		self.enemySpawners = {}
		self:placeEnemySpawners(3)
	end
end