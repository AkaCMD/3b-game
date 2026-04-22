require("tests.test_bootstrap")

require("src.entity")
require("src.world")
require("src.enemy_spawner")
require("src.edge")
require("src.level")

local T = require("tests.helpers.testlib")

local function with_test_world(run)
    local originalWorld = rawget(_G, "World")
    local WorldClass = World
    local world = WorldClass()
    _G.World = world

    local ok, err = pcall(run, world)

    _G.World = originalWorld
    if not ok then
        error(err, 0)
    end
end

return {
    {
        name = "Level 可触发横纵形状变化随机事件",
        run = function()
            with_test_world(function()
                local level = Level(vec2(100, 100), 480, 480, 0, false)
                local picks = { 3, 1 }
                local pickIndex = 0

                local function random_int()
                    pickIndex = pickIndex + 1
                    return picks[pickIndex]
                end

                local eventId = level:randomEvent(random_int)

                T.assert_equal(eventId, LevelEvent.ShapeShift)
                T.assert_close(level.hs.x, 240 * 1.3)
                T.assert_close(level.hs.y, 240 * 0.82)
                T.assert_close(level.edgeSlots[1].startPos.x, 100 - level.hs.x)
                T.assert_close(level.edgeSlots[2].endPos.y, 100 + level.hs.y)
            end)
        end,
    },
    {
        name = "Level 收缩事件会按轴压缩边界",
        run = function()
            with_test_world(function()
                local level = Level(vec2(200, 200), 480, 480, 0, false)
                local picks = { 2, 2 }
                local pickIndex = 0

                local function random_int()
                    pickIndex = pickIndex + 1
                    return picks[pickIndex]
                end

                local eventId = level:randomEvent(random_int)

                T.assert_equal(eventId, LevelEvent.Shrink)
                T.assert_close(level.hs.x, 240)
                T.assert_close(level.hs.y, 240 * 0.7)
                T.assert_equal(level.lastEventLabel, "边界上下收缩")
            end)
        end,
    },
    {
        name = "Level 重置尺寸后会回到基础长宽",
        run = function()
            with_test_world(function()
                local level = Level(vec2(160, 160), 480, 480, 0, false)

                level:apply_boundary_factors(1.4, 0.72)
                level:resetLevelScale()

                T.assert_close(level.hs.x, 240)
                T.assert_close(level.hs.y, 240)
                T.assert_close(level.edgeSlots[3].startPos.x, 160 + 240)
                T.assert_close(level.edgeSlots[4].endPos.y, 160 - 240)
            end)
        end,
    },
}
