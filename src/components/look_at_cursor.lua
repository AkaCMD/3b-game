LookAtCursor = class({
    name = "LookAtCursor",
    default_tostring = true,
})

function LookAtCursor:update(entity)
    local mouseX, mouseY = love.mouse.getPosition()
    entity.rotation = math.atan2(mouseY - entity.pos.y, mouseX - entity.pos.x) + math.pi/2
end

return LookAtCursor
