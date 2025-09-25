EnemySpawner = class({
    name = "EnemySpawner",
    extends = Entity,
    default_tostring = true
})

---@class EnemySpawner
---@param pos vec2
---@param spawnTime number
function EnemySpawner:new(pos, spawnTime)
    self:super(pos, vec2(0, 0))
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
    self.hasCollision = false
end

function EnemySpawner:update(dt)
    self.waveTimer:update(dt)
end

function EnemySpawner:spawnWave()
    World:add_entity(Enemy(vec2(self.pos.x, self.pos.y), 0, vec2(1.5, 1.5), 100))
end

function EnemySpawner:draw()
    love.graphics.setColor(PALETTE.red)
    love.graphics.circle("fill", self.pos.x, self.pos.y, 8)
    love.graphics.setColor(1, 1, 1, 1)
end