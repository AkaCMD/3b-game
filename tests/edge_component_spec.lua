require("tests.test_bootstrap")

require("src.entity")
require("src.world")
require("src.enemy_spawner")
require("src.edge")

local T = require("tests.helpers.testlib")

return {
    {
        name = "Edge 会按类型装配对应组件",
        run = function()
            local edge = Edge(vec2(0, 0), vec2(10, 0), EdgeType.Normal)

            T.assert_true(edge:get_component("draw_line") ~= nil)
            T.assert_true(edge:get_component("contact_rule") ~= nil)
            T.assert_true(edge:get_component("portal") == nil)
            T.assert_true(edge:get_component("enemy_spawners") == nil)
        end,
    },
    {
        name = "Portal Edge 默认会销毁普通玩家子弹，仅穿梭子弹可传送",
        run = function()
            local a, b = CreatePortalPair(vec2(0, 0), vec2(10, 0), vec2(20, 0), vec2(30, 0))

            local normalBullet = Entity(vec2(5, 2), vec2(1, 1))
            normalBullet:set_tag("bullet")
            normalBullet:set_tag("player_bullet")
            a:onCollide(normalBullet)
            T.assert_true(not normalBullet.isValid)

            local warpBullet = Entity(vec2(5, 2), vec2(1, 1))
            warpBullet:set_tag("bullet")
            warpBullet:set_tag("player_bullet")
            warpBullet.canWarpEdges = true
            a:onCollide(warpBullet)

            T.assert_close(warpBullet.pos.x, 25)
            T.assert_close(warpBullet.pos.y, 8)

            local enemyBullet = Entity(vec2(5, 2), vec2(1, 1))
            enemyBullet:set_tag("bullet")
            enemyBullet:set_tag("enemy_bullet")
            a:onCollide(enemyBullet)

            T.assert_true(not enemyBullet.isValid)
        end,
    },
    {
        name = "SpawnEnemy Edge 在加入世界和几何变化后会重建刷怪器",
        run = function()
            local WorldClass = World
            local world = WorldClass()
            local edge = Edge(vec2(0, 0), vec2(30, 0), EdgeType.SpawnEnemy)

            T.assert_equal(#edge:get_enemy_spawners(), 0)

            world:add_entity(edge)
            T.assert_equal(#edge:get_enemy_spawners(), 3)
            T.assert_equal(#world.entities, 4)

            edge.startPos = vec2(0, 0)
            edge.endPos = vec2(60, 0)
            edge:refresh_geometry()
            world:update(0)

            T.assert_equal(#edge:get_enemy_spawners(), 3)
            T.assert_equal(#world.entities, 4)
        end,
    },
}
