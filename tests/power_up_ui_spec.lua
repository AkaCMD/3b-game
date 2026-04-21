require("tests.test_bootstrap")

require("src.button")
require("src.text")
require("src.power_up_ui")

local T = require("tests.helpers.testlib")

local function make_player()
    return {
        upgradeLevels = {},
        get_upgrade_level = function(self, id)
            return self.upgradeLevels[id] or 0
        end,
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
                    title = "边界穿梭",
                    description = "玩家子弹可穿越绿色边界",
                    max_level = 1,
                    apply = function() end,
                },
            }

            ui:buildElements()

            local button = ui.elements[1]
            T.assert_equal(button.text, "边界穿梭")
            T.assert_equal(button.titleText, "边界穿梭")
            T.assert_equal(button.descriptionText, "玩家子弹可穿越绿色边界")
            T.assert_equal(button.footerText, "Lv.1/1")
        end,
    },
}
