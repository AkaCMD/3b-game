require("tests.test_bootstrap")

require("src.entity")
require("src.bullet")
require("src.enemy")
require("src.enemy_spawner")

local T = require("tests.helpers.testlib")

return {
    {
        name = "护盾敌人会挡住正面子弹",
        run = function()
            local enemy = Enemy(vec2(10, 10), 0, vec2(1, 1), 100, {
                enemyType = EnemyType.Shielded,
            })
            local bullet = Bullet(vec2(20, 10), 0, vec2(1, 1), 100, BulletType.PlayerBullet)

            bullet:onCollide(enemy)

            T.assert_true(not bullet.isValid)
            T.assert_true(enemy.isValid)
            T.assert_equal(enemy.health, 1)
        end,
    },
    {
        name = "护盾敌人会被背后子弹击破",
        run = function()
            local enemy = Enemy(vec2(10, 10), 0, vec2(1, 1), 100, {
                enemyType = EnemyType.Shielded,
            })
            local bullet = Bullet(vec2(0, 10), 0, vec2(1, 1), 100, BulletType.PlayerBullet)

            bullet:onCollide(enemy)

            T.assert_true(not bullet.isValid)
            T.assert_true(not enemy.isValid)
            T.assert_equal(enemy.health, 0)
        end,
    },
    {
        name = "刷怪器会在后续波次混入护盾敌人",
        run = function()
            local spawner = EnemySpawner(vec2(0, 0))
            local spawned = {}

            function spawner:spawn(entity)
                table.insert(spawned, entity)
                return entity
            end

            spawner:spawnWave(2, 4)

            T.assert_equal(#spawned, 2)
            T.assert_equal(spawned[1].enemyType, EnemyType.Normal)
            T.assert_equal(spawned[2].enemyType, EnemyType.Shielded)
        end,
    },
}
