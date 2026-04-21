require("tests.test_bootstrap")

local CursorEffects = require("src.cursor_effects")
local T = require("tests.helpers.testlib")

return {
    {
        name = "准星移动时应产生跟手延迟与倾斜拉伸",
        run = function()
            local state = CursorEffects.new_state(0, 0)
            CursorEffects.update_state(state, 100, 0, 0.016, false)

            T.assert_true(state.render_x > 0, "准星渲染位置应向目标移动")
            T.assert_true(state.render_x < 100, "准星渲染位置应保留轻微跟手延迟")
            T.assert_true(state.rotation > 0, "向右移动时应产生正向倾斜")
            T.assert_true(state.scale_x > state.scale_y, "高速移动时应产生横向拉伸")
        end,
    },
    {
        name = "准星开火时应产生脉冲抖动并逐渐衰减",
        run = function()
            local state = CursorEffects.new_state(50, 50)
            CursorEffects.update_state(state, 50, 50, 0.016, true)

            T.assert_true(state.pulse > 0, "开火后应有脉冲")
            T.assert_true(math.abs(state.offset_y) > 0, "开火后应有抖动偏移")

            local pulse_after_fire = state.pulse
            CursorEffects.update_state(state, 50, 50, 0.2, false)
            T.assert_true(state.pulse < pulse_after_fire, "停止开火后脉冲应衰减")
        end,
    },
}
