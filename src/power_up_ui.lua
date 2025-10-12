PowerupScreenUI = class({
    name = "PowerupScreenUI",
    default_tostring = true
})

local POWERUP_OPTIONS = {
    {
        text = "Warpable Bullet",
        callback = function ()
            print("powerup 1!")
        end
    },
    {
        text = "Portal Gun",
        callback = function ()
            print("powerup 2")
        end
    },
    {
        text = "Sheild",
        callback = function ()
            print("powerup 3")
        end
    },
}

function PowerupScreenUI:new(player_ref)
    self.elements = {}
    self.player = player_ref
    self.active = false
    self:initElements()
end

function PowerupScreenUI:initElements()
    local buttonWidth, buttonHeight = 200, 450
    local spacing = 20
    local totalWidth = (#POWERUP_OPTIONS * buttonWidth) + ((#POWERUP_OPTIONS - 1) * spacing)
    local startX = (SCREEN_WIDTH - totalWidth) / 2

    for i, options in ipairs(POWERUP_OPTIONS) do
        local x = startX + (i - 1) * (buttonWidth + spacing)
        local y = (SCREEN_HEIGHT - buttonHeight) / 2
        local callback = function(btn)
            print("Selected: " .. btn.text)
            if options.callback then
                options.callback(self.player)
            end
            self:hide()
        end
        local btn = Button(x, y, buttonWidth, buttonHeight, options.text, callback)
        btn.fontSize = 20
        table.insert(self.elements, btn)
    end

    local title = Text("Choose an Upgrade", 24, PALETTE.white, SCREEN_WIDTH/2, 30, true, 0)
    table.insert(self.elements, title)
end

function PowerupScreenUI:draw()
    if not self.active then return end

    for _, element in ipairs(self.elements) do
        element:draw()
    end
end

function PowerupScreenUI:update(dt)
    if not self.active then return end

    for _, element in ipairs(self.elements) do
        if element.update then
            element:update(dt)
        end
    end
end

function PowerupScreenUI:mousereleased(x, y, button)
    if not self.active then return end

    for i = #self.elements, 1, -1 do
        local element = self.elements[i]
        if element.handleClick and element.hovered then
            element:handleClick()
            break
        end
    end
end

function PowerupScreenUI:show()
    love.mouse.setVisible(true)
    self.active = true
end

function PowerupScreenUI:hide()
    love.mouse.setVisible(false)
    self.active = false
end

function PowerupScreenUI:isActive()
    return self.active
end