local Component = require("src.component")

CollisionAction = class({
    name = "CollisionAction",
    extends = Component,
    default_tostring = true,
})

---@param tags? string|string[]
---@return string[]
local function clone_tags(tags)
    if tags == nil then
        return {}
    end

    if type(tags) == "string" then
        return { tags }
    end

    local result = {}
    for i, tag in ipairs(tags) do
        result[i] = tag
    end
    return result
end

---@param options table
function CollisionAction:new(options)
    options = options or {}
    self:super(options)
    self.targetTags = clone_tags(options.targetTags or options.target_tags)
    self.match = options.match or options.filter
    self.action = assert(options.action or options.apply, "CollisionAction requires action callback")
    self.consumeSelf = options.consume_self == true or options.consumeSelf == true
    self.consumeOther = options.consume_other == true or options.consumeOther == true
    self.maxTriggers = options.max_triggers or options.maxTriggers
    self.triggerCount = 0
end

---@param _entity Entity
function CollisionAction:reset(_entity)
    self.triggerCount = 0
end

---@param entity Entity
---@param other Entity
---@param context? table
---@return boolean
function CollisionAction:matches(entity, other, context)
    if not other or not other.isValid then
        return false
    end

    if #self.targetTags > 0 then
        local matched = false
        for _, tag in ipairs(self.targetTags) do
            if other:has_tag(tag) then
                matched = true
                break
            end
        end
        if not matched then
            return false
        end
    end

    if self.match and not self.match(entity, other, context, self) then
        return false
    end

    return true
end

---@param entity Entity
---@param other Entity
---@param context? table
function CollisionAction:on_collide(entity, other, context)
    if self.maxTriggers and self.triggerCount >= self.maxTriggers then
        return
    end

    if not self:matches(entity, other, context) then
        return
    end

    local applied = self.action(entity, other, context, self)
    if applied == false then
        return
    end

    self.triggerCount = self.triggerCount + 1

    if self.consumeOther and other.free then
        other:free()
    end

    if self.consumeSelf then
        entity:free()
    end
end

return CollisionAction
