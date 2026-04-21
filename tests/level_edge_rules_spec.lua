require("tests.test_bootstrap")

local LevelEdgeRules = require("src.level_edge_rules")
local T = require("tests.helpers.testlib")

local function make_random_int(sequence)
    local index = 0
    return function(min, max)
        index = index + 1
        local value = sequence[index]
        if value < min or value > max then
            error(("随机整数越界：%s 不在 [%s, %s]"):format(value, min, max))
        end
        return value
    end
end

return {
    {
        name = "边规则生成器可产出双向传送门布局",
        run = function()
            local layout = LevelEdgeRules.build_layout(
                make_random_int({2, 1, 1, 2}),
                function() return 0.2 end
            )

            T.assert_equal(#LevelEdgeRules.list_positions(layout), 4)
            T.assert_equal(LevelEdgeRules.count_kind(layout, LevelEdgeRules.EdgeKind.Portal), 2)
            T.assert_equal(layout[2].target, 1)
            T.assert_equal(layout[1].target, 2)
            T.assert_true(LevelEdgeRules.count_kind(layout, LevelEdgeRules.EdgeKind.SpawnEnemy) >= 1)
        end,
    },
    {
        name = "边规则生成器在无传送门时仍保证至少一条刷怪边",
        run = function()
            local layout = LevelEdgeRules.build_layout(
                make_random_int({3, 1, 2, 1}),
                function() return 0.9 end
            )

            T.assert_equal(#LevelEdgeRules.list_positions(layout), 4)
            T.assert_equal(LevelEdgeRules.count_kind(layout, LevelEdgeRules.EdgeKind.Portal), 0)
            T.assert_true(LevelEdgeRules.count_kind(layout, LevelEdgeRules.EdgeKind.SpawnEnemy) >= 1)
        end,
    },
}
