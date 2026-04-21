AutoFire = class({
    name = "AutoFire",
    default_tostring = true,
})

function AutoFire:new(options)
    options = options or {}
    self.cooldown = options.cooldown or 0.5
    self.elapsed = self.cooldown
    self.should_fire = options.should_fire or function()
        return true
    end
    self.create_projectile = assert(options.create_projectile, "AutoFire requires create_projectile")
end

function AutoFire:update(entity, dt)
    self.elapsed = self.elapsed + dt
    if self.elapsed < self.cooldown then
        return
    end

    if not self.should_fire(entity) then
        return
    end

    local projectile = self.create_projectile(entity)
    if projectile then
        entity:spawn(projectile)
        self.elapsed = 0
    end
end

return AutoFire
