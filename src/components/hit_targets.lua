HitTargets = class({
    name = "HitTargets",
    default_tostring = true,
})

function HitTargets:new(options)
    options = options or {}
    self.targetTags = options.targetTags or {}
    self.damage = options.damage or 1
    self.destroyOnHit = options.destroyOnHit ~= false
    self.should_hit = options.should_hit
    self.on_hit = options.on_hit
end

function HitTargets:matches(other)
    for _, tag in ipairs(self.targetTags) do
        if other:has_tag(tag) then
            return true
        end
    end
    return false
end

function HitTargets:on_collide(entity, other)
    if not other or not other.isValid or not self:matches(other) then
        return
    end

    if self.should_hit and not self.should_hit(entity, other) then
        return
    end

    local damageable = other.get_component and other:get_component("damageable")
    if not damageable then
        return
    end

    local applied = damageable:apply_damage(other, self.damage, entity)
    if not applied then
        return
    end

    if self.on_hit then
        self.on_hit(entity, other)
    end

    if self.destroyOnHit then
        entity:free()
    end
end

return HitTargets
