local Component = require("src.component")

SeekTarget = class({
    name = "SeekTarget",
    extends = Component,
    default_tostring = true,
})

---@param options? table
function SeekTarget:new(options)
    options = options or {}
    self:super(options)
    self.targetTag = options.targetTag or options.target_tag or "player"
    self.resolve_target = options.resolve_target
    self.moveSpeed = options.moveSpeed or options.speed or 100
    self.rotateSpeed = options.rotateSpeed or 3
    self.moveEnabled = options.move_enabled ~= false
    self.rotateEnabled = options.rotate_enabled ~= false
end

---@param entity Entity
---@param context? table
---@return Entity|nil
function SeekTarget:get_target(entity, context)
    if self.resolve_target then
        return self.resolve_target(entity, context, self)
    end

    local world = entity.world
    if not world then
        return nil
    end

    if self.targetTag == "player" and world.get_player then
        return world:get_player()
    end

    if world.find_first_by_tag then
        return world:find_first_by_tag(self.targetTag)
    end

    return nil
end

---@param entity Entity
---@param dt number
---@param context? table
function SeekTarget:update(entity, dt, context)
    local target = self:get_target(entity, context)
    if not target or not target.pos then
        return
    end

    local dir = target.pos - entity.pos
    if dir:length_squared() <= 0 then
        return
    end

    dir:normalise_inplace()
    local targetAngle = math.atan2(dir.y, dir.x)

    if self.rotateEnabled then
        local angleDiff = (targetAngle - entity.rotation + math.pi) % (2 * math.pi) - math.pi
        entity.rotation = entity.rotation + angleDiff * self.rotateSpeed * dt
    end

    if not self.moveEnabled then
        return
    end

    local moveDir
    if self.rotateEnabled then
        moveDir = vec2(math.cos(entity.rotation), math.sin(entity.rotation))
    else
        moveDir = dir
    end

    entity.pos:add_inplace(moveDir:scalar_mul_inplace(self.moveSpeed * dt))
end

return SeekTarget
