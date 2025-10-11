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
    local buttonWidth, buttonHeight = 200, 50
end

function PowerupScreenUI:draw()
    
end

function PowerupScreenUI:update(dt)
    
end

function PowerupScreenUI:mousereleased(x, y, button)
    
end

function PowerupScreenUI:show()
    
end

function PowerupScreenUI:hide()
    
end

function PowerupScreenUI:isActive()
    return self.active
end