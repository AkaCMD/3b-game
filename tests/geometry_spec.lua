require("tests.test_bootstrap")

local Geometry = require("src.geometry")
local T = require("tests.helpers.testlib")

return {
    {
        name = "project_ratio_on_segment 会对线段外投影结果进行钳制",
        run = function()
            T.assert_equal(Geometry.project_ratio_on_segment(-10, 0, 0, 0, 10, 0), 0)
            T.assert_equal(Geometry.project_ratio_on_segment(5, 0, 0, 0, 10, 0), 0.5)
            T.assert_equal(Geometry.project_ratio_on_segment(20, 0, 0, 0, 10, 0), 1)
        end,
    },
    {
        name = "segment_hitbox 会根据边方向返回正确尺寸",
        run = function()
            local w1, h1 = Geometry.segment_hitbox(0, 0, 12, 0, 5)
            T.assert_equal(w1, 12)
            T.assert_equal(h1, 5)

            local w2, h2 = Geometry.segment_hitbox(0, 0, 0, 12, 5)
            T.assert_equal(w2, 5)
            T.assert_equal(h2, 12)
        end,
    },
    {
        name = "portal_exit 会把位置映射到目标边并沿法线推出偏移",
        run = function()
            local x, y, t = Geometry.portal_exit(
                5, 2,
                0, 0,
                10, 0,
                20, 0,
                30, 0,
                8
            )

            T.assert_equal(t, 0.5)
            T.assert_close(x, 25)
            T.assert_close(y, 8)
        end,
    },
    {
        name = "rectangle_corners 会生成带偏移的矩形四角",
        run = function()
            local corners = Geometry.rectangle_corners(10, 10, 4, 6, 2)
            T.assert_equal(corners[1].x, 4)
            T.assert_equal(corners[1].y, 2)
            T.assert_equal(corners[3].x, 16)
            T.assert_equal(corners[3].y, 18)
        end,
    },
    {
        name = "point_within 会正确判断点是否在矩形内",
        run = function()
            T.assert_true(Geometry.point_within(5, 5, 0, 0, 10, 10))
            T.assert_true(not Geometry.point_within(0, 0, 0, 0, 10, 10))
            T.assert_true(not Geometry.point_within(15, 5, 0, 0, 10, 10))
        end,
    },
}
