EdgeDrawLine = class({
    name = "EdgeDrawLine",
    default_tostring = true,
})

function EdgeDrawLine:new(color)
    self.color = color or { 1, 1, 1, 1 }
end

function EdgeDrawLine:draw(entity)
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4] or 1)
    love.graphics.line(entity.startPos.x, entity.startPos.y, entity.endPos.x, entity.endPos.y)
    love.graphics.setColor(PALETTE.white)
end

return EdgeDrawLine
