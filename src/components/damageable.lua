Damageable = class({
    name = "Damageable",
    default_tostring = true,
})

function Damageable:new(options)
    options = options or {}
    self.maxHealth = options.maxHealth or options.health or 1
    self.health = options.health or self.maxHealth
    self.invulnerabilityComponent = options.invulnerabilityComponent
    self.can_take_damage = options.can_take_damage
    self.on_damaged = options.on_damaged
    self.on_death = options.on_death
end

function Damageable:init(entity)
    self.health = self.health or self.maxHealth
    entity.health = self.health
end

function Damageable:set_health(entity, health)
    self.health = math.max(health, 0)
    entity.health = self.health
    return self.health
end

function Damageable:change_health(entity, delta)
    return self:set_health(entity, self.health + delta)
end

function Damageable:can_apply_damage(entity, amount, source)
    if self.can_take_damage and not self.can_take_damage(entity, self, amount, source) then
        return false
    end

    if self.invulnerabilityComponent then
        local invulnerability = entity:get_component(self.invulnerabilityComponent)
        if invulnerability and invulnerability.is_active and invulnerability:is_active() then
            return false
        end
    end

    return true
end

function Damageable:apply_damage(entity, amount, source)
    if not self:can_apply_damage(entity, amount, source) then
        return false
    end

    self:set_health(entity, self.health - amount)

    if self.on_damaged then
        self.on_damaged(entity, amount, source, self)
    end

    if self.health <= 0 then
        if self.on_death then
            self.on_death(entity, source, self)
        else
            entity:free()
        end
    end

    return true
end

return Damageable
