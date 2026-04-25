require("tests.test_bootstrap")

require("src.wave_manager")

local T = require("tests.helpers.testlib")

local FakeSpawner = class({
    name = "FakeSpawner",
    default_tostring = true,
})

function FakeSpawner:new()
    self.calls = {}
end

---@param enemyCount integer
---@param waveNumber integer
---@return integer
function FakeSpawner:spawnWave(enemyCount, waveNumber)
    table.insert(self.calls, {
        enemyCount = enemyCount,
        waveNumber = waveNumber,
    })
    return enemyCount
end

local FakeWorld = class({
    name = "FakeWorld",
    default_tostring = true,
})

---@param spawners? table[]
function FakeWorld:new(spawners)
    self.spawners = spawners or {}
    self.enemyCount = 0
end

---@param tag string
---@return table[]
function FakeWorld:find_all_by_tag(tag)
    if tag == "enemy_spawner" then
        return self.spawners
    end
    if tag == "enemy" then
        local result = {}
        for i = 1, self.enemyCount do
            result[i] = true
        end
        return result
    end
    return {}
end

return {
    {
        name = "WaveManager 会在计时结束后生成新波次",
        run = function()
            local spawner = FakeSpawner()
            local world = FakeWorld({ spawner })
            local manager = WaveManager(world, {
                initial_delay = 0.1,
            })

            manager:update(0.2)

            T.assert_equal(manager.currentWave, 1)
            T.assert_equal(#spawner.calls, 1)
            T.assert_equal(spawner.calls[1].enemyCount, 1)
        end,
    },
    {
        name = "WaveManager 会在完成指定波次后触发升级",
        run = function()
            local spawner = FakeSpawner()
            local world = FakeWorld({ spawner })
            local upgradeTriggered = false
            local manager = WaveManager(world, {
                initial_delay = 0,
                upgrade_every = 1,
                on_upgrade_ready = function()
                    upgradeTriggered = true
                    return true
                end,
            })

            manager:update(0.01)
            manager.waveActive = true
            world.enemyCount = 0
            manager:update(0.01)

            T.assert_true(upgradeTriggered)
            T.assert_true(manager.awaitingUpgradeSelection)
        end,
    },
    {
        name = "WaveManager 会限制同屏敌人上限",
        run = function()
            local spawner = FakeSpawner()
            local world = FakeWorld({ spawner })
            local manager = WaveManager(world, {
                max_active_enemies = 2,
                max_spawn_per_step = 10,
            })

            manager.currentWave = 1
            manager.pendingEnemiesToSpawn = 5
            world.enemyCount = 1

            local spawned = manager:spawn_pending_enemies(world.enemyCount)

            T.assert_equal(spawned, 1)
            T.assert_equal(manager.pendingEnemiesToSpawn, 4)
            T.assert_equal(#spawner.calls, 1)
        end,
    },
    {
        name = "WaveManager 会限制单帧刷怪批量以避免卡顿尖峰",
        run = function()
            local spawnerA = FakeSpawner()
            local spawnerB = FakeSpawner()
            local world = FakeWorld({ spawnerA, spawnerB })
            local manager = WaveManager(world, {
                max_active_enemies = 20,
                max_spawn_per_step = 2,
            })

            manager.currentWave = 1
            manager.pendingEnemiesToSpawn = 5

            local spawned = manager:spawn_pending_enemies(0)

            T.assert_equal(spawned, 2)
            T.assert_equal(manager.pendingEnemiesToSpawn, 3)
            T.assert_equal(#spawnerA.calls + #spawnerB.calls, 2)
        end,
    },
}
