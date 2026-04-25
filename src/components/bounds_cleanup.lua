BoundsCleanup = class({
    name = "BoundsCleanup",
    default_tostring = true,
})

---@param options? table
function BoundsCleanup:new(options)
    options = options or {}
    self.delay = options.delay or 0
    self.elapsed = 0
end

---@param entity Entity
---@param dt number
---@param context? table
function BoundsCleanup:update(entity, dt, context)
    self.elapsed = self.elapsed + dt
    if self.elapsed < self.delay then
        return
    end

    local level = context and context.level
    if level and not level:containsPoint(entity.pos) then
        entity:free()
    end
end

return BoundsCleanup
