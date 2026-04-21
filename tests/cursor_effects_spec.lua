require("tests.test_bootstrap")

local CursorEffects = require("src.cursor_effects")
local T = require("tests.helpers.testlib")

return {
    {
        name = "准星随鼠标右移应向右摆动",
        run = function()
            local state = CursorEffects.new_state(0, 0)
            CursorEffects.update_state(state, 100, 0, 0.016, false)

            T.assert_equal(100, state.render_x, "准星位置应直接跟随鼠标")
            T.assert_equal(0, state.offset_x, "不应有额外横向偏移")
            T.assert_true(state.rotation > 0, "向右移动时应产生正向摆动")
            T.assert_equal(1, state.scale_x, "不应有缩放特效")
            T.assert_equal(1, state.scale_y, "不应有缩放特效")
        end,
    },
    {
        name = "准星随鼠标左移应向左摆动并回正",
        run = function()
            local state = CursorEffects.new_state(100, 0)
            CursorEffects.update_state(state, 0, 0, 0.016, false)
            T.assert_true(state.rotation < 0, "向左移动时应产生负向摆动")

            local rotated = state.rotation
            CursorEffects.update_state(state, 0, 0, 0.2, false)
            T.assert_true(math.abs(state.rotation) < math.abs(rotated), "停止移动后摆动应回正")
        end,
    },
}
