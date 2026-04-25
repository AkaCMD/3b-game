local UpgradeDefinitions = {}

local definitions = {
    {
        id = "bullet_size",
        title = "Heavy Rounds",
        description = "Bullet size +25%",
        max_level = 4,
        ---@param player Player
        apply = function(player)
            player.upgrades.bullet_scale = player.upgrades.bullet_scale + 0.25
        end,
    },
    {
        id = "boundary_warp",
        title = "Boundary Warp",
        description = "Your bullets pierce green boundaries",
        max_level = 1,
        ---@param player Player
        apply = function(player)
            player.upgrades.bullet_boundary_warp_enabled = true
        end,
    },
    {
        id = "move_speed",
        title = "Light Frame",
        description = "Move speed +15%",
        max_level = 5,
        ---@param player Player
        apply = function(player)
            player.upgrades.move_speed_multiplier = player.upgrades.move_speed_multiplier + 0.15
        end,
    },
    {
        id = "fire_rate",
        title = "Overclocked Feed",
        description = "Fire rate +12%",
        max_level = 5,
        ---@param player Player
        apply = function(player)
            player.upgrades.fire_rate_multiplier = player.upgrades.fire_rate_multiplier + 0.12
        end,
    },
    {
        id = "boundary_boost",
        title = "Boundary Surge",
        description = "Gain short buff after portal travel",
        max_level = 3,
        ---@param player Player
        apply = function(player)
            player.upgrades.boundary_boost_enabled = true
            player.upgrades.boundary_boost_duration = player.upgrades.boundary_boost_duration + 1.0
            player.upgrades.boundary_boost_move_multiplier = player.upgrades.boundary_boost_move_multiplier + 0.1
            player.upgrades.boundary_boost_fire_multiplier = player.upgrades.boundary_boost_fire_multiplier + 0.08
        end,
    },
    {
        id = "restore_health",
        title = "Emergency Repairs",
        description = "Restore 1 health",
        max_level = 3,
        ---@param player Player
        apply = function(player)
            local damageable = player.get_component and player:get_component("damageable") or nil
            if damageable then
                local nextHealth = math.min(damageable.health + 1, damageable.maxHealth or damageable.health + 1)
                damageable:set_health(player, nextHealth)
            else
                player.health = player.health + 1
            end
        end,
    },
}

---@param list table
local function shuffle(list)
    for i = #list, 2, -1 do
        local j = math.random(i)
        list[i], list[j] = list[j], list[i]
    end
end

---@return table[]
function UpgradeDefinitions.get_all()
    return definitions
end

---@param player Player
---@param id string
---@return integer
function UpgradeDefinitions.get_level(player, id)
    if player and player.get_upgrade_level then
        return player:get_upgrade_level(id)
    end
    return 0
end

---@param player Player
---@param definition table
---@return boolean
function UpgradeDefinitions.is_available(player, definition)
    local level = UpgradeDefinitions.get_level(player, definition.id)
    local maxLevel = definition.max_level or math.huge
    return level < maxLevel
end

---@param player Player
---@param count? integer
---@return table[]
function UpgradeDefinitions.pick_options(player, count)
    local available = {}
    for _, definition in ipairs(definitions) do
        if UpgradeDefinitions.is_available(player, definition) then
            table.insert(available, definition)
        end
    end

    shuffle(available)

    local options = {}
    for i = 1, math.min(count or 3, #available) do
        table.insert(options, available[i])
    end
    return options
end

return UpgradeDefinitions
