require("tests.test_bootstrap")

local UpgradeDefinitions = require("src.upgrade_definitions")
local T = require("tests.helpers.testlib")

local function make_player()
    return {
        health = 3,
        upgradeLevels = {},
        upgrades = {
            bullet_scale = 1.0,
            bullet_boundary_warp_enabled = false,
            move_speed_multiplier = 1.0,
            fire_rate_multiplier = 1.0,
            boundary_boost_enabled = false,
            boundary_boost_duration = 4.0,
            boundary_boost_move_multiplier = 1.35,
            boundary_boost_fire_multiplier = 1.25,
        },
        ---@param self table
        ---@param id string
        ---@return integer
        get_upgrade_level = function(self, id)
            return self.upgradeLevels[id] or 0
        end,
    }
end

return {
    {
        name = "升级池不会返回已满级的选项",
        run = function()
            local player = make_player()
            player.upgradeLevels.boundary_warp = 1

            local options = UpgradeDefinitions.pick_options(player, 6)

            for _, option in ipairs(options) do
                T.assert_true(option.id ~= "boundary_warp")
            end
        end,
    },
    {
        name = "边界穿梭升级会启用子弹边界穿梭",
        run = function()
            local player = make_player()
            local boundaryWarp
            for _, definition in ipairs(UpgradeDefinitions.get_all()) do
                if definition.id == "boundary_warp" then
                    boundaryWarp = definition
                    break
                end
            end

            boundaryWarp.apply(player)

            T.assert_true(player.upgrades.bullet_boundary_warp_enabled)
        end,
    },
}
