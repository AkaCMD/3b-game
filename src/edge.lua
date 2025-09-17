-- TODO: different functionalities
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
	if math.abs(finish.x - start.x) > math.abs(finish.y - start.y) then
		self.hitbox = vec2(self.length, 5)
	else
		self.hitbox = vec2(5, self.length)
	end
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
end

---@param num integer Number of enemy spawners in this edge
function Edge:placeEnemySpawners(num)
end

function Edge:update()
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

	-- Draw another lower edge
	if self.edgeType == EdgeType.Portal then
		local dx = self.endPos.x - self.startPos.x
		local dy = self.endPos.y - self.startPos.y
		local len = math.sqrt(dx * dx + dy * dy)

		if len > 0 then
			local nx = -dy / len * len
			local ny = dx / len * len

			local p1x = self.startPos.x + nx
			local p1y = self.startPos.y + ny
			local p2x = self.endPos.x + nx
			local p2y = self.endPos.y + ny

			love.graphics.line(p1x, p1y, p2x, p2y)
		end
	end

	love.graphics.setColor(PALETTE.white)
end