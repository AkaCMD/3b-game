TimedCollisionUnlock = class({
    name = "TimedCollisionUnlock",
    default_tostring = true,
})

function TimedCollisionUnlock:new(delay)
    self.delay = delay or 1
    self.remaining = self.delay
end

function TimedCollisionUnlock:init(entity)
    entity.hasCollision = false
end

function TimedCollisionUnlock:update(entity, dt)
    if entity.hasCollision then
        return
    end

    self.remaining = self.remaining - dt
    if self.remaining <= 0 then
        entity.hasCollision = true
    end
end

return TimedCollisionUnlock
