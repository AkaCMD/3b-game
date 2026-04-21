TrackTarget = class({
    name = "TrackTarget",
    default_tostring = true,
})

function TrackTarget:new(options)
    options = options or {}
    self.speed = options.speed or 100
    self.rotateSpeed = options.rotateSpeed or 3
    self.targetTag = options.targetTag or "player"
end

function TrackTarget:update(entity, dt)
    local world = entity.world
    local target = world and world:find_first_by_tag(self.targetTag) or player
    if not target or not target.pos then
        return
    end

    local dir = target.pos - entity.pos
    if dir:length_squared() <= 0 then
        return
    end

    dir:normalise_inplace()
    local targetAngle = math.atan2(dir.y, dir.x)
    local angleDiff = (targetAngle - entity.rotation + math.pi) % (2 * math.pi) - math.pi
    entity.rotation = entity.rotation + angleDiff * self.rotateSpeed * dt

    local moveDir = vec2(math.cos(entity.rotation), math.sin(entity.rotation))
    entity.pos:add_inplace(moveDir:scalar_mul_inplace(self.speed * dt))
end

return TrackTarget
