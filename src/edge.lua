-- TODO: make it static
-- add collision shape
-- different functionalities
Edge = class({
	name = "Edge",
	extends = Entity,
	default_tostring = true
})

EdgeType = {SpawnEnemy = 1, Portal = 2, Damagable = 3}

---@class Edge
---@param start vec2
---@param finish vec2
---@param edgeTypeIndex integer
function Edge:new(start, finish, edgeTypeIndex)
	---@class Edge:Entity
	self.midPos = vec2((start.x + finish.x) / 2, (start.y + finish.y) / 2)
	self:super(self.midPos, vec2(1, 1))
	self.startPos = start
	self.endPos = finish
	self.length = vec2.length(finish:vector_sub(start))
	self.edgeType = edgeTypeIndex
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
	love.graphics.setColor(PALETTE.white)
end