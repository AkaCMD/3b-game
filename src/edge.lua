Edge = class({
	name = "Edge",
	extends = Entity,
	default_tostring = true
})

EdgeType = {SpawnEnemy = 1, Portal = 2, Damagable = 3}

---@param start vec2
---@param finish vec2
---@param edgeType integer
function Edge:new(start, finish, edgeType)
	local pos = vec2((start.x + finish.x) / 2, (start.y + finish.y) / 2)
end