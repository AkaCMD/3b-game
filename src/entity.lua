vec2 = Batteries.vec2
Entity = class({
	name = "Entity",
	default_tostring = true
})

---@param values? string|string[]
---@return table
local function clone_list(values)
    if values == nil then
        return {}
    end

    if type(values) == "string" then
        return { values }
    end

    local result = {}
    for i, value in ipairs(values) do
        result[i] = value
    end
    return result
end

---@param component Component|table
---@return boolean
local function is_component_enabled(component)
    return component.enabled ~= false
end

---@param a Component|table
---@param b Component|table
---@return boolean
local function compare_components(a, b)
    local ap = a.priority or 0
    local bp = b.priority or 0
    if ap == bp then
        return (a._component_order or 0) < (b._component_order or 0)
    end
    return ap < bp
end

COLLIDER_TYPE = {
    dynamic = 0,
    static = 1,
    trigger = 2,
}

---Make an entity
---@param pos vec2
---@param scale vec2
---@param collider_type? integer
---@class Entity
---@field rotation number
---@field pos vec2
---@field scale vec2
---@field hitbox vec2
---@field hs vec2
---@field hasCollision boolean
---@field isValid boolean
---@field health integer
---@field colliderType integer
function Entity:new(pos, scale, collider_type)
    self.rotation = 0
	self.pos = pos or vec2(0, 0)
	self.scale = scale or vec2(1, 1)
	self.hitbox = vec2(10, 10)
	self.hs = self.hitbox:pooled_copy():scalar_mul_inplace(0.5)
	self.hasCollision = true
	self.isValid = true
	self.health = 3
    self.colliderType = collider_type or COLLIDER_TYPE.dynamic
    self.components = {}
    self.componentIndex = {}
    self._nextComponentOrder = 0
    self.tags = {}
    self.world = nil
end

---@param name string
---@param component Component|table
---@return Component|table
function Entity:_normalise_component(name, component)
    component.id = component.id or name
    component.name = component.name or component.id
    component.priority = component.priority or 0
    if component.enabled == nil then
        component.enabled = true
    end
    component.requires = clone_list(component.requires)
    self._nextComponentOrder = self._nextComponentOrder + 1
    component._component_order = self._nextComponentOrder
    return component
end

function Entity:_sort_components()
    table.sort(self.components, compare_components)
end

---@param name string
---@param component Component|table
function Entity:_validate_component(name, component)
    for _, dependency in ipairs(component.requires) do
        assert(self.componentIndex[dependency] ~= nil, ("Component '%s' requires missing component '%s'"):format(name, dependency))
    end

    if component.validate then
        local ok, err = component:validate(self)
        assert(ok ~= false, err or ("Component '%s' failed validation"):format(name))
    end
end

---@param name string
---@param component Component|table
---@return Component|table
function Entity:add_component(name, component)
    assert(name ~= nil and component ~= nil, "Entity:add_component requires name and component")
    local existing = self.componentIndex[name]
    if existing then
        self:remove_component(name)
    end

    component = self:_normalise_component(name, component)
    self.componentIndex[name] = component
    table.insert(self.components, component)
    self:_sort_components()
    self:_validate_component(name, component)

    if component.init then
        component:init(self)
    end

    if self.world and component.on_added_to_world then
        component:on_added_to_world(self, self.world)
    end

    return component
end

---@param name string
---@return Component|table|nil
function Entity:get_component(name)
    return self.componentIndex[name]
end

---@param name string
---@return boolean
function Entity:has_component(name)
    return self.componentIndex[name] ~= nil
end

---@param name string
---@return Component|table
function Entity:require_component(name)
    local component = self.componentIndex[name]
    assert(component ~= nil, ("Entity missing required component '%s'"):format(name))
    return component
end

---@param name string
---@param enabled boolean
---@return Component|table|nil
function Entity:enable_component(name, enabled)
    local component = self.componentIndex[name]
    if not component then
        return nil
    end

    if component.set_enabled then
        component:set_enabled(enabled)
    else
        component.enabled = enabled ~= false
    end
    return component
end

---@param name string
---@return Component|table|nil
function Entity:remove_component(name)
    local component = self.componentIndex[name]
    if not component then
        return nil
    end

    for i = #self.components, 1, -1 do
        if self.components[i] == component then
            table.remove(self.components, i)
            break
        end
    end
    self.componentIndex[name] = nil

    if component.on_removed_from_world and self.world then
        component:on_removed_from_world(self, self.world)
    end

    if component.reset then
        component:reset(self)
    end

    return component
end

---@param tag string
---@param enabled? boolean
function Entity:set_tag(tag, enabled)
    if enabled == false then
        self.tags[tag] = nil
        return
    end
    self.tags[tag] = true
end

---@param tag string
---@return boolean
function Entity:has_tag(tag)
    return self.tags[tag] == true
end

---@param world World
function Entity:on_added_to_world(world)
    self.world = world
    for _, component in ipairs(self.components) do
        if component.on_added_to_world then
            component:on_added_to_world(self, world)
        end
    end
end

---@param world World
function Entity:on_removed_from_world(world)
    for _, component in ipairs(self.components) do
        if component.on_removed_from_world then
            component:on_removed_from_world(self, world)
        end
    end
    self.world = nil
end

---@param entity Entity
---@return Entity
function Entity:spawn(entity)
    if self.world then
        return self.world:add_entity(entity)
    end
    if World and World.add_entity then
        return World:add_entity(entity)
    end
    return entity
end

---@param eventName string
---@param payload? table
function Entity:emit(eventName, payload)
    if self.world and self.world.publish then
        self.world:publish(eventName, payload)
        return
    end
    if bus and bus.publish then
        bus:publish(eventName, payload)
    end
end

---@param dt number
---@param context? table
function Entity:update(dt, context)
    for _, component in ipairs(self.components) do
        if is_component_enabled(component) and component.update then
            component:update(self, dt, context)
        end
    end
end

function Entity:draw()
    for _, component in ipairs(self.components) do
        if is_component_enabled(component) and component.draw then
            component:draw(self)
        end
    end
end

---@param other Entity
---@return boolean
function Entity:overlaps(other)
	if not self.hasCollision or not other.hasCollision then
		return false
	end
	return intersect.aabb_aabb_overlap(self.pos, self.hs, other.pos, other.hs)
end

---@param other Entity
---@param into vec2
---@return msv|false result
function Entity:collide(other, into)
	if not self.hasCollision or not other.hasCollision then
        return false
    end
	return intersect.aabb_aabb_collide(self.pos, self.hs, other.pos, other.hs, into)
end

---@param other Entity
---@param balance number
---@return msv|false msv
function Entity:resolveCollision(other, balance)
	if not self.hasCollision or not other.hasCollision then
		return false
	end
	balance = balance or 0.5
	local msv = self:collide(other)
	if msv then
		intersect.resolve_msv(self.pos, other.pos, msv, balance)
	end
	return msv
end

---@param x number
---@param y number
function Entity:moveTo(x, y)
    self.pos:set(x, y)
end

function Entity:drawHitbox()
	if not self.hasCollision then
		return
	end

    if self.colliderType == COLLIDER_TYPE.dynamic then
        love.graphics.setColor(1, 0, 0, 1)
    elseif self.colliderType == COLLIDER_TYPE.static then
        love.graphics.setColor(0.5, 0.5, 0.5, 0.7)
    elseif self.colliderType == COLLIDER_TYPE.trigger then
        love.graphics.setColor(1.0, 1.0, 0.2, 0.5)
    end
    local hs = self.hs:pooled_copy():vector_mul(self.scale)
    local corners = {
        vec2:pooled(self.pos.x - hs.x, self.pos.y - hs.y),
        vec2:pooled(self.pos.x + hs.x, self.pos.y - hs.y),
        vec2:pooled(self.pos.x + hs.x, self.pos.y + hs.y),
        vec2:pooled(self.pos.x - hs.x, self.pos.y + hs.y)
    }
    if self.rotation ~= 0 then
        local cos_r = math.cos(self.rotation)
        local sin_r = math.sin(self.rotation)
        for _, corner in ipairs(corners) do
            corner:vector_sub_inplace(self.pos)
            local x = corner.x * cos_r - corner.y * sin_r
            local y = corner.x * sin_r + corner.y * cos_r
            corner.x, corner.y = x, y
            corner:vector_add_inplace(self.pos)
        end
    end
    love.graphics.line(
        corners[1].x, corners[1].y,
        corners[2].x, corners[2].y,
        corners[3].x, corners[3].y,
        corners[4].x, corners[4].y,
        corners[1].x, corners[1].y
    )
    vec2.release(hs, corners[1], corners[2], corners[3], corners[4])
    love.graphics.setColor(PALETTE.white)
end

function Entity:free()
	self.isValid = false
end

---@param other Entity
function Entity:onCollide(other)
    for _, component in ipairs(self.components) do
        if is_component_enabled(component) and component.on_collide then
            component:on_collide(self, other)
        end
    end
end
