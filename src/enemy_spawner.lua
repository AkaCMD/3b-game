EnemySpawner = class({
    name = "EnemySpawner",
    default_tostring = true
})

---@class EnemySpawner
function EnemySpawner:new()
    self.waveTimer = batteries.timer:new(
        3.0,
        nil,
        function(_, timer)
            self:spawnWave()
            timer:reset()
        end
    )
end

function EnemySpawner:update(dt)
    self.waveTimer:update(dt)
end

function EnemySpawner:spawnWave()
    print("callback")
end