FloatY = class({
    name = "FloatY",
    default_tostring = true,
})

---@param amplitude? number
---@param frequency? number
function FloatY:new(amplitude, frequency)
    self.amplitude = amplitude or 5
    self.frequency = frequency or 1.5
    self.time = 0
    self.baseY = nil
end

---@param entity Entity
function FloatY:init(entity)
    self.baseY = entity.pos.y
end

---@param entity Entity
---@param dt number
function FloatY:update(entity, dt)
    if not self.baseY then
        self.baseY = entity.pos.y
    end
    self.time = self.time + dt
    entity.pos.y = sinwave(self.baseY, self.time, self.amplitude, self.frequency)
end

return FloatY
