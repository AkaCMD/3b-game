local Component = require("src.component")

LookAtTarget = class({
    name = "LookAtTarget",
    extends = Component,
    default_tostring = true,
})

local function unpack_target(targetOrX, targetY)
    if type(targetOrX) == "table" and targetOrX.x and targetOrX.y then
        return targetOrX.x, targetOrX.y
    end
    return targetOrX, targetY
end

function LookAtTarget:new(options)
    options = options or {}
    self:super(options)
    self.angleOffset = options.angle_offset or options.angleOffset or 0
    self.get_target_position = options.get_target_position or options.target_position or function()
        return love.mouse.getPosition()
    end
end

function LookAtTarget:update(entity, _dt, context)
    local tx, ty = unpack_target(self.get_target_position(entity, context, self))
    if tx == nil or ty == nil then
        return
    end

    entity.rotation = math.atan2(ty - entity.pos.y, tx - entity.pos.x) + self.angleOffset
end

return LookAtTarget
