local UpgradeDefinitions = require("src.upgrade_definitions")

PowerupScreenUI = class({
    name = "PowerupScreenUI",
    default_tostring = true
})

function PowerupScreenUI:new(player_ref, on_upgrade_selected)
    self.player = player_ref
    self.active = false
    self.elements = {}
    self.options = {}
    self.onUpgradeSelected = on_upgrade_selected
end

function PowerupScreenUI:buildElements()
    self.elements = {}

    local buttonWidth, buttonHeight = 200, 260
    local spacing = 20
    local totalWidth = (#self.options * buttonWidth) + ((#self.options - 1) * spacing)
    local startX = (SCREEN_WIDTH - totalWidth) / 2

    for i, option in ipairs(self.options) do
        local x = startX + (i - 1) * (buttonWidth + spacing)
        local y = (SCREEN_HEIGHT - buttonHeight) / 2
        local callback = function(btn)
            print("Selected: " .. btn.text)
            option.apply(self.player)
            self.player:increment_upgrade_level(option.id)
            if self.onUpgradeSelected then
                self.onUpgradeSelected(option)
            end
            love.audio.play(Sfx_power_up)
            self:hide()
        end
        local nextLevel = self.player:get_upgrade_level(option.id) + 1
        local maxLevel = option.max_level or nextLevel
        local btn = Button(x, y, buttonWidth, buttonHeight, option.title, callback)
        btn.titleText = option.title
        btn.descriptionText = option.description or ""
        btn.footerText = ("Lv.%d/%d"):format(nextLevel, maxLevel)
        btn.titleFontSize = 20
        btn.descriptionFontSize = 14
        btn.footerFontSize = 14
        table.insert(self.elements, btn)
    end

    local title = Text("Choose an Upgrade", 24, PALETTE.white, SCREEN_WIDTH/2, 100, true, 0)
    local subtitle = Text("Clear more waves to keep building your loadout", 14, PALETTE.green, SCREEN_WIDTH/2, 135, true, 0)
    table.insert(self.elements, title)
    table.insert(self.elements, subtitle)
end

function PowerupScreenUI:draw()
    if not self.active then return end

    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    love.graphics.setColor(PALETTE.white)

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

function PowerupScreenUI:offer_random_upgrades()
    self.options = UpgradeDefinitions.pick_options(self.player, 3)
    if #self.options == 0 then
        return false
    end

    self:buildElements()
    self:show()
    return true
end
