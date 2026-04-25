require("tests.test_bootstrap")

require("src.entity")
require("src.world")
require("src.enemy")
require("src.enemy_spawner")
require("src.edge")

local T = require("tests.helpers.testlib")

return {
    {
        name = "Edge 会保留私有玩法状态而不是挂载专用组件",
        run = function()
            local edge = Edge(vec2(0, 0), vec2(10, 0), EdgeType.Portal)
            local target = Edge(vec2(20, 0), vec2(30, 0), EdgeType.Normal)

            edge:set_portal_target(target)

            T.assert_true(edge:get_component("portal") == nil)
            T.assert_true(edge.portalTarget == target)
            T.assert_equal(#edge:get_enemy_spawners(), 0)
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
    {
        name = "刷怪器生成的敌人会向场地内侧偏移，避免卡在边界外",
        run = function()
            local world = World()
            local edge = Edge(vec2(10, -30), vec2(10, 30), EdgeType.SpawnEnemy)
            edge.levelCenter = vec2(0, 0)
            world:add_entity(edge)

            local spawner = edge:get_enemy_spawners()[2]
            spawner:spawnWave(1, 1)
            world:update(0)

            local enemy = world:find_first_by_tag("enemy")
            T.assert_true(enemy ~= nil)
            T.assert_true(enemy.pos.x < 10, "敌人应生成在右侧边界的内侧")
        end,
    },
    {
        name = "刷怪器生成的敌人初始朝向场地内侧，避免出生后冲出边界",
        run = function()
            local world = World()
            local edge = Edge(vec2(10, -30), vec2(10, 30), EdgeType.SpawnEnemy)
            edge.levelCenter = vec2(0, 0)
            world:add_entity(edge)

            local player = Entity(vec2(0, 0), vec2(1, 1))
            player:set_tag("player")
            player.hasCollision = false
            world:add_entity(player)

            local spawner = edge:get_enemy_spawners()[2]
            spawner:spawnWave(1, 1)
            world:update(0)

            local enemy = world:find_first_by_tag("enemy")
            T.assert_true(enemy ~= nil)
            local initialX = enemy.pos.x

            for _ = 1, 10 do
                world:update(1 / 60)
            end

            T.assert_true(enemy.pos.x < initialX, "敌人出生后应先向场地内侧移动")
            T.assert_true(enemy.pos.x < 10, "敌人不应越过右侧刷怪边界外侧")
        end,
    },
    {
        name = "刷怪器会避开已占用位置，防止同波敌人堆叠",
        run = function()
            local world = World()
            local edge = Edge(vec2(10, -30), vec2(10, 30), EdgeType.SpawnEnemy)
            edge.levelCenter = vec2(0, 0)
            world:add_entity(edge)

            local spawner = edge:get_enemy_spawners()[2]
            local blockingEnemy = Enemy(vec2(-4, 0), 0, vec2(1, 1), 0)
            world:add_entity(blockingEnemy)

            spawner:spawnWave(1, 1)
            world:update(0)

            local enemies = world:find_all_by_tag("enemy")
            T.assert_equal(#enemies, 2)
            T.assert_true(not enemies[1]:overlaps(enemies[2]), "新敌人不应与已存在敌人重叠")
        end,
    },
}
