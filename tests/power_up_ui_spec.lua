require("tests.test_bootstrap")

require("src.button")
require("src.text")
require("src.power_up_ui")

local T = require("tests.helpers.testlib")

local function make_player()
    return {
        upgradeLevels = {},
        ---@param self table
        ---@param id string
        ---@return integer
        get_upgrade_level = function(self, id)
            return self.upgradeLevels[id] or 0
        end,
        ---@param self table
        ---@param id string
        increment_upgrade_level = function(self, id)
            self.upgradeLevels[id] = (self.upgradeLevels[id] or 0) + 1
        end,
    }
end

return {
    {
        name = "升级界面按钮会带标题描述和等级文案",
        run = function()
            local ui = PowerupScreenUI(make_player())
            ui.options = {
                {
                    id = "boundary_warp",
                    title = "Boundary Warp",
                    description = "Your bullets pierce green boundaries",
                    max_level = 1,
                    apply = function() end,
                },
            }

            ui:buildElements()

            local button = ui.elements[1]
            T.assert_equal(button.text, "Boundary Warp")
            T.assert_equal(button.titleText, "Boundary Warp")
            T.assert_equal(button.descriptionText, "Your bullets pierce green boundaries")
            T.assert_equal(button.footerText, "Lv.1/1")
        end,
    },
}
