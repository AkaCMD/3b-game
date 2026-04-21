RepeatingTimer = class({
    name = "RepeatingTimer",
    default_tostring = true,
})

function RepeatingTimer:new(interval, callback)
    self.interval = interval or 1
    self.callback = assert(callback, "RepeatingTimer requires callback")
    self.elapsed = 0
end

function RepeatingTimer:update(entity, dt)
    self.elapsed = self.elapsed + dt
    while self.elapsed >= self.interval do
        self.elapsed = self.elapsed - self.interval
        self.callback(entity)
    end
end

return RepeatingTimer
