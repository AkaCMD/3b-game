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

function FakeWorld:new(spawners)
    self.spawners = spawners or {}
    self.enemyCount = 0
end

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
}
