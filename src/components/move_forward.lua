MoveForward = class({
    name = "MoveForward",
    default_tostring = true,
})

---@param entity Entity
---@param dt number
function MoveForward:update(entity, dt)
    entity.pos.x = entity.pos.x + math.cos(entity.rotation) * entity.speed * dt
    entity.pos.y = entity.pos.y + math.sin(entity.rotation) * entity.speed * dt
end

return MoveForward
