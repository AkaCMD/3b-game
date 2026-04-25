require("tests.test_bootstrap")

require("src.entity")
require("src.world")
require("src.Item")
require("src.bullet")
require("src.enemy")
require("src.player")

local T = require("tests.helpers.testlib")

return {
    {
        name = "玩家子弹应能命中并消灭敌人",
        run = function()
            local world = World()
            local enemy = Enemy(vec2(100, 100), 0, vec2(1, 1), 0)
            local bullet = Bullet(vec2(100, 100), 0, vec2(1, 1), 0, BulletType.PlayerBullet)

            world:add_entity(enemy)
            world:add_entity(bullet)
            world:check_collisions()

            T.assert_true(not enemy.isValid, "敌人应被玩家子弹击杀")
            T.assert_true(not bullet.isValid, "玩家子弹命中后应销毁")
        end,
    },
    {
        name = "敌方子弹应能命中玩家",
        run = function()
            local world = World()
            local player = Player(vec2(100, 100), vec2(1, 1))
            local bullet = Bullet(vec2(100, 100), 0, vec2(1, 1), 0, BulletType.EnemyBullet)

            world:add_entity(player)
            world:add_entity(bullet)
            world:check_collisions()

            T.assert_equal(player.health, 5, "玩家应受到 1 点伤害")
            T.assert_true(not bullet.isValid, "敌方子弹命中后应销毁")
        end,
    },
}
