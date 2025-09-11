World = class({
	name = "World",
	default_tostring = true
})

function World:new()
	self.entities = {}
end

---@param en Entity
function World:add_entity(en)
    table.insert(self.entities, en)
end

--- Remove invalid entities
---@param idx integer
function World:remove_entity(idx)
    table.remove(self.entities, idx)
end

---- Update all entities in the world
---@param dt number
function World:update(dt, level)
	for i = #self.entities, 1, -1 do
	    local entity = self.entities[i]
	    if entity.isValid then
	        entity:update(dt, (entity:is(Player) or entity:is(Bullet) or entity:is(Enemy)) and level or nil)
	    else
	        self:remove_entity(i)
	    end
	end
end

---- Check Collisions between entities
function World:check_collisions()
    for i = 1, #self.entities - 1 do
		for j = i + 1, #self.entities do
			local a, b = self.entities[i], self.entities[j]
			if a:overlaps(b) then
				-- If enemy got shot
				a:onCollide(b)
				b:onCollide(a)
				print("Collision between " .. tostring(a) .. " and " .. tostring(b))
				local msv = a:resolveCollision(b, 0.5)
			end
		end
	end
end

function World:clear()
    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]
        entity:free()
        table.remove(self.entities, i)
    end
end