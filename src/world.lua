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
    local en = table.remove(self.entities, idx)
	en:free()
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
			---@type Entity, Entity
			local a, b = self.entities[i], self.entities[j]
			if a:overlaps(b) then
				-- If enemy got shot
				a:onCollide(b)
				b:onCollide(a)

				local at, bt = a.colliderType, b.colliderType
				if at == COLLIDER_TYPE.trigger or bt == COLLIDER_TYPE.trigger then
					-- trigger vs trigger
				elseif at == COLLIDER_TYPE.static and bt == COLLIDER_TYPE.static then
					-- static vs static
				elseif at == COLLIDER_TYPE.dynamic and bt == COLLIDER_TYPE.static then
					-- dynamic vs static
					a:resolveCollision(b, 1.0)
				elseif at == COLLIDER_TYPE.static and bt == COLLIDER_TYPE.dynamic then
					-- static vs dynamic
					b:resolveCollision(a, 1.0)
				elseif at == COLLIDER_TYPE.dynamic and bt == COLLIDER_TYPE.dynamic then
					-- dynamic vs dynamic
					a:resolveCollision(b, 0.5)
				end
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

function World:clear_all_enemies()
	for i = #self.entities, 1, -1 do
        local entity = self.entities[i]
		if entity:is(Enemy) then
			for i = 1, 5, 1 do
                local dir = math.random(-30, 30) / 10;
                local distance = math.random(0, 5);
                BloodBatch:add(entity.pos.x + math.cos(dir)*distance, entity.pos.y + math.sin(dir)*distance, math.random(-30, 30) / 10, 3, 3, 6, 1);
            end
		    entity:free()
        	table.remove(self.entities, i)
		end
    end
end

function World:clear_all_enemy_bullets()
	for i = #self.entities, 1, -1 do
        local entity = self.entities[i]
		if entity:is(Bullet) and entity.bulletType == BulletType.EnemyBullet then
		    entity:free()
        	table.remove(self.entities, i)
		end
    end
end