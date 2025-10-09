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

function Button:new(x, y, width, height, text, onClickCallback)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.text = text or "Button"
    self.onClick = onClickCallback or function() print("Button clicked: " .. self.text) end

    self.hoveredId = nil
    self.lastHoveredId = nil
    self.clickCount = 0
end