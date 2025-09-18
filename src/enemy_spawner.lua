EnemySpawner = class({
    name = "EnemySpawner",
    default_tostring = true
})

---@class EnemySpawner
---@param pos vec2
---@param spawnTime number
function EnemySpawner:new(pos, spawnTime)
    self.pos = pos or vec2(300, 300)
    self.waveTimer = Batteries.timer(
        spawnTime or 6.0,
        nil,
        function(_, timer)
            self:spawnWave()
            timer:reset()
        end
    )
    self.pos = pos or vec2(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
end

function EnemySpawner:update(dt)
    self.waveTimer:update(dt)
end

function EnemySpawner:spawnWave()
    World:add_entity(Enemy(self.pos, 0, vec2(1.5, 1.5), 100))
end