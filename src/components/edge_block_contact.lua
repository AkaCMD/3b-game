EdgeBlockContact = class({
    name = "EdgeBlockContact",
    default_tostring = true,
})

function EdgeBlockContact:new(options)
    options = options or {}
    self.label = options.label or "Edge"
    self.destroyBullets = options.destroyBullets ~= false
end

function EdgeBlockContact:on_collide(entity, other)
    if other:has_tag("player") then
        logger.info(self.label)
        return
    end

    if self.destroyBullets and other:has_tag("bullet") then
        other:free()
    end
end

return EdgeBlockContact
