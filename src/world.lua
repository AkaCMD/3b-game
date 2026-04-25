local PubsubImpl = Batteries.pubsub or require("lib.batteries.pubsub")

World = class({
	name = "World",
	default_tostring = true
})

function World:new()
	self.entities = {}
    self.pendingEntities = {}
    self.eventBus = PubsubImpl()
    self.isIterating = false
    self.playerEntity = nil
end

---@param en Entity
---@return Entity
function World:_attach_entity(en)
    table.insert(self.entities, en)
    if en.on_added_to_world then
        en:on_added_to_world(self)
    else
        en.world = self
    end
    if en.has_tag and en:has_tag("player") then
        self.playerEntity = en
    end
    return en
end

function World:_flush_pending_entities()
    if #self.pendingEntities == 0 then
        return
    end

    for _, entity in ipairs(self.pendingEntities) do
        self:_attach_entity(entity)
    end
    self.pendingEntities = {}
end

---@param en Entity
function World:add_entity(en)
    if not en then
        return nil
    end

    if self.isIterating then
        table.insert(self.pendingEntities, en)
        return en
    end

    return self:_attach_entity(en)
end

--- Remove invalid entities
---@param idx integer
function World:remove_entity(idx)
    local en = table.remove(self.entities, idx)
    if not en then
        return nil
    end
    if self.playerEntity == en then
        self.playerEntity = nil
    end
    if en.isValid then
	    en:free()
    end
    if en.on_removed_from_world then
        en:on_removed_from_world(self)
    else
        en.world = nil
    end
    return en
end

---@param eventName string
---@param payload? table
function World:publish(eventName, payload)
    self.eventBus:publish(eventName, payload)
end

---@param eventName string
---@param handler function
function World:subscribe(eventName, handler)
    self.eventBus:subscribe(eventName, handler)
end

---@param tag string
---@return Entity|nil
function World:find_first_by_tag(tag)
    for _, entity in ipairs(self.entities) do
        if entity.isValid and entity:has_tag(tag) then
            return entity
        end
    end
    return nil
end

---@param tag string
---@return Entity[]
function World:find_all_by_tag(tag)
    local result = {}
    for _, entity in ipairs(self.entities) do
        if entity.isValid and entity:has_tag(tag) then
            table.insert(result, entity)
        end
    end
    return result
end

---@param tag string
---@return integer
function World:get_tag_count(tag)
    local count = 0
    for _, entity in ipairs(self.entities) do
        if entity.isValid and entity:has_tag(tag) then
            count = count + 1
        end
    end
    return count
end

function World:get_player()
    if self.playerEntity and self.playerEntity.isValid then
        return self.playerEntity
    end

    self.playerEntity = self:find_first_by_tag("player")
    return self.playerEntity
end

---- Update all entities in the world
---@param dt number
---@param level? Level
function World:update(dt, level)
    self.isIterating = true
    local context = {
        world = self,
        level = level,
    }

	for i = #self.entities, 1, -1 do
	    local entity = self.entities[i]
	    if entity.isValid then
	        entity:update(dt, context)
	    else
	        self:remove_entity(i)
	    end
	end

    self.isIterating = false
    self:_flush_pending_entities()
end

---- Check Collisions between entities
function World:check_collisions()
    self.isIterating = true
    for i = 1, #self.entities - 1 do
		for j = i + 1, #self.entities do
			---@type Entity, Entity
			local a, b = self.entities[i], self.entities[j]
            if a.isValid and b.isValid and a:overlaps(b) then
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
    self.isIterating = false
    self:_flush_pending_entities()
end

function World:clear()
    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]
        entity:free()
        if entity.on_removed_from_world then
            entity:on_removed_from_world(self)
        else
            entity.world = nil
        end
        table.remove(self.entities, i)
    end
    self.pendingEntities = {}
    self.playerEntity = nil
end

function World:clear_all_enemies()
	for i = #self.entities, 1, -1 do
        local entity = self.entities[i]
		if entity:has_tag("enemy") then
			for _ = 1, 5 do
                local dir = math.random(-30, 30) / 10
                local distance = math.random(0, 5)
                BloodBatch:add(entity.pos.x + math.cos(dir)*distance, entity.pos.y + math.sin(dir)*distance, math.random(-30, 30) / 10, 3, 3, 6, 1)
            end
		    entity:free()
            self:remove_entity(i)
		end
    end
end

function World:clear_all_enemy_bullets()
	for i = #self.entities, 1, -1 do
        local entity = self.entities[i]
		if entity:has_tag("enemy_bullet") then
		    entity:free()
            self:remove_entity(i)
		end
    end
end
