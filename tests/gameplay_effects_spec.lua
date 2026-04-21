require("tests.test_bootstrap")

local GameplayEffects = require("src.gameplay_effects")
local T = require("tests.helpers.testlib")

return {
    {
        name = "升级暂停时不应绘制屏幕震动",
        run = function()
            T.assert_true(not GameplayEffects.should_draw_shake(0.1, 0.2, true))
        end,
    },
    {
        name = "震动时间在暂停期间也应继续推进直至结束",
        run = function()
            local elapsed = GameplayEffects.advance_shake_time(0.1, 0.2, 0.15)
            T.assert_close(elapsed, 0.25)
            T.assert_true(not GameplayEffects.should_draw_shake(elapsed, 0.2, false))
        end,
    },
}
