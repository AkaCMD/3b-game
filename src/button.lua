Button = class({
    name = "Button",
    default_tostring = true
})

local colours = {
    text = { 0.2109375, 0.30859375, 0.41796875, 0.99609375 },
    button = { 0.9375, 0.9375, 0.9375, 0.99609375 },
    background = { 0.26171875, 0.86328125, 0.8984375, 0.99609375 },
    highlight = { 0.984375, 0.31640625, 0.51953125, 0.99609375 },
}

local function firstOnly(currentVal, previousValRef)
   local first = (currentVal ~= previousValRef.val)
   previousValRef.val = currentVal
   if first then
    return currentVal
   end
   return nil
end

function Button:new(x, y, width, height, text, onClickCallback)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.text = text or "Button"
    self.fontSize = 24
    self.onClick = onClickCallback or function() print("Button clicked: " .. self.text) end

    self.hovered = false
    self.rotation = 0
    self.lastHoverState = { val = false }
    self.lastClickState = { val = false }

    if not Button.hoverSfx then
        
    end
    if not Button.clickSfx then
        
    end
end

function Button:draw()
    local lg = love.graphics

    lg.push()
    lg.translate(self.x, self.y)
    lg.translate(self.width/2, self.height/2)
    lg.rotate(self.rotation * 5)
    lg.translate(-self.width/2, -self.height/2)

    local mx, my = love.mouse.getPosition()
    local screenX, screenY = lg.inverseTransformPoint(mx, my)

    -- detect if hovered
    local hover = point_within(screenX, screenY, 0, 0, self.width, self.height)
    self.hovered = hover

    if hover then
        lg.setColor(colours.highlight)
    else
        lg.setColor(colours.button)
    end
    lg.rectangle("fill", 0, 0, self.width, self.height)

    lg.setColor(colours.text)
    local font = Assets.fonts.RasterForgeRegular(self.fontSize)
    love.graphics.setFont(font)
    lg.printf(self.text, 0, (self.height - font:getHeight()) / 2, self.width, "center")

    lg.pop()
end

function Button:update(dt)
    self.rotation = self.rotation + dt
    local firstHover = firstOnly(self.hovered, self.lastHoverState)
    if firstHover and Button.hoverSfx then
        
    end
end

function Button.checkClicks(buttons)
    local x, y, button = love.mouse.getX(), love.mouse.getY(), 1
    if button ~= 1 then return end

    for _, btn in ipairs(buttons) do
        if btn.hovered then
            btn:handleClick()
            break
        end
    end
end

function Button:handleClick()
    local firstClick = firstOnly(true, self.lastClickState)
    if firstClick then
        self.clickCount = (self.clickCount or 0) + 1
        if self.onClick then
            self.onClick(self)
        end
        if Button._clickSfx then
        end
    end
end