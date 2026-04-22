require("src.enemy")

EnemySpawner = class({
    name = "EnemySpawner",
    extends = Entity,
    default_tostring = true
})

---@class EnemySpawner
---@param pos vec2
function EnemySpawner:new(pos)
    self:super(pos, vec2(0, 0))
    self.pos = pos or vec2(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
    self.hasCollision = false
    self.lastWaveNumber = 0
    self.waveSpawnIndex = 0
    self:set_tag("enemy_spawner")
end

function EnemySpawner:update(dt, context)
    Entity.update(self, dt, context)
end

function EnemySpawner:next_enemy_type_for_wave(waveNumber)
    waveNumber = waveNumber or 1
    if self.lastWaveNumber ~= waveNumber then
        self.lastWaveNumber = waveNumber
        self.waveSpawnIndex = 0
    end

    self.waveSpawnIndex = self.waveSpawnIndex + 1

    if waveNumber < 4 then
        return EnemyType.Normal
    end

    if waveNumber < 8 then
        if self.waveSpawnIndex % 2 == 0 then
            return EnemyType.Shielded
        end
        return EnemyType.Normal
    end

    if waveNumber < 12 then
        if self.waveSpawnIndex % 3 ~= 0 then
            return EnemyType.Shielded
        end
        return EnemyType.Normal
    end

    return EnemyType.Shielded
end

function EnemySpawner:spawnWave(enemyCount, waveNumber)
    enemyCount = enemyCount or 1
    waveNumber = waveNumber or 1

    local spawned = 0
    local tx, ty = 1, 0
    if self.parentEdge then
        local dx = self.parentEdge.endPos.x - self.parentEdge.startPos.x
        local dy = self.parentEdge.endPos.y - self.parentEdge.startPos.y
        local length = math.sqrt(dx * dx + dy * dy)
        if length > 0 then
            tx = dx / length
            ty = dy / length
        end
    end

    local spread = 18
    local enemySpeed = 100 + math.min(waveNumber - 1, 10) * 8
    for i = 1, enemyCount do
        local offset = (i - (enemyCount + 1) / 2) * spread
        local spawnPos = vec2(self.pos.x + tx * offset, self.pos.y + ty * offset)
        local enemyType = self:next_enemy_type_for_wave(waveNumber)
        self:spawn(Enemy(spawnPos, 0, vec2(1.5, 1.5), enemySpeed, {
            enemyType = enemyType,
        }))
        spawned = spawned + 1
    end

    return spawned
end

function EnemySpawner:draw()
    love.graphics.setColor(PALETTE.red)
    love.graphics.circle("fill", self.pos.x, self.pos.y, 8)
    love.graphics.setColor(1, 1, 1, 1)
end
