PickupOnTouch = class({
    name = "PickupOnTouch",
    default_tostring = true,
})

function PickupOnTouch:new(options)
    options = options or {}
    self.targetTags = options.targetTags or { "player" }
    self.consumeOnPickup = options.consumeOnPickup ~= false
    self.on_pickup = assert(options.on_pickup, "PickupOnTouch requires on_pickup")
end

function PickupOnTouch:matches(other)
    for _, tag in ipairs(self.targetTags) do
        if other:has_tag(tag) then
            return true
        end
    end
    return false
end

function PickupOnTouch:on_collide(entity, other)
    if not other or not other.isValid or not self:matches(other) then
        return
    end

    self.on_pickup(entity, other)
    if self.consumeOnPickup then
        entity:free()
    end
end

return PickupOnTouch
