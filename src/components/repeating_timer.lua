RepeatingTimer = class({
    name = "RepeatingTimer",
    default_tostring = true,
})

---@param interval? number
---@param callback fun(entity: Entity)
function RepeatingTimer:new(interval, callback)
    self.interval = interval or 1
    self.callback = assert(callback, "RepeatingTimer requires callback")
    self.elapsed = 0
end

---@param entity Entity
---@param dt number
function RepeatingTimer:update(entity, dt)
    self.elapsed = self.elapsed + dt
    while self.elapsed >= self.interval do
        self.elapsed = self.elapsed - self.interval
        self.callback(entity)
    end
end

return RepeatingTimer
