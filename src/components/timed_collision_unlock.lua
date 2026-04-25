TimedCollisionUnlock = class({
    name = "TimedCollisionUnlock",
    default_tostring = true,
})

---@param delay? number
function TimedCollisionUnlock:new(delay)
    self.delay = delay or 1
    self.remaining = self.delay
    self.originalColliderType = nil
end

---@param entity Entity
function TimedCollisionUnlock:init(entity)
    self.originalColliderType = entity.colliderType
    entity.hasCollision = true
    entity.colliderType = COLLIDER_TYPE.trigger
end

---@param entity Entity
---@param dt number
function TimedCollisionUnlock:update(entity, dt)
    if entity.colliderType == self.originalColliderType then
        return
    end

    self.remaining = self.remaining - dt
    if self.remaining <= 0 then
        entity.colliderType = self.originalColliderType or COLLIDER_TYPE.dynamic
    end
end

return TimedCollisionUnlock
