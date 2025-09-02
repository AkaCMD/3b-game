UI = class({
    name = "UI",
    default_tostring = true
})

---@param text string
---@param size integer
---@param fontColor number[]
---@param x number
---@param y number
---@param isCentered boolean
---@param rot number
function UI:new(text, size, fontColor, x, y, isCentered, rot)
    self.content = text or ""
    self.fontSize = size or 16
    self.r = fontColor[1] or 1
    self.g = fontColor[2] or 1
    self.b = fontColor[3] or 1
    self.a = fontColor[4] or 1
    self.x = x or 0
    self.y = y or 0
    self.isCentered = isCentered or false
    self.rot = rot or 0
end

function UI:draw()
love.graphics.push()
    love.graphics.setColor(self.r, self.g, self.b, self.a)
    local font = Assets.fonts.RasterForgeRegular(self.fontSize)
    love.graphics.setFont(font)

    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rot)
    love.graphics.scale(self.scale, self.scale)

    if self.isCentered then
        local text_width = font:getWidth(self.content)
        local text_height = font:getHeight()
        love.graphics.printf(self.content, -text_width / 2, -text_height / 2, text_width, "center")
    else
        love.graphics.print(self.content, 0, 0)
    end

    love.graphics.setColor(1, 1, 1, 1)
love.graphics.pop()
end