require("src.enemy")
local Geometry = require("src.geometry")

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

---@param dt number
---@param context? table
function EnemySpawner:update(dt, context)
    Entity.update(self, dt, context)
end

---@param waveNumber? integer
---@return integer
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

---@param ax number
---@param ay number
---@param bx number
---@param by number
---@return number
local function distance_squared(ax, ay, bx, by)
    local dx = ax - bx
    local dy = ay - by
    return dx * dx + dy * dy
end

---@return number, number, number, number
function EnemySpawner:get_spawn_axes()
    local tx, ty = 1, 0
    local nx, ny = 0, 0

    if self.parentEdge then
        local dx = self.parentEdge.endPos.x - self.parentEdge.startPos.x
        local dy = self.parentEdge.endPos.y - self.parentEdge.startPos.y
        local length = math.sqrt(dx * dx + dy * dy)
        if length > 0 then
            tx = dx / length
            ty = dy / length
        end

        local levelCenter = self.parentEdge.levelCenter or vec2(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
        nx, ny = Geometry.segment_normal_towards_point(
            self.parentEdge.startPos.x,
            self.parentEdge.startPos.y,
            self.parentEdge.endPos.x,
            self.parentEdge.endPos.y,
            levelCenter.x,
            levelCenter.y
        )
    end

    return tx, ty, nx, ny
end

---@param x number
---@param y number
---@param occupiedPositions vec2[]
---@param minDistanceSq number
---@return boolean
function EnemySpawner:is_position_occupied(x, y, occupiedPositions, minDistanceSq)
    for _, pos in ipairs(occupiedPositions) do
        if distance_squared(x, y, pos.x, pos.y) < minDistanceSq then
            return true
        end
    end

    local world = self.world
    if not world then
        return false
    end

    for _, enemy in ipairs(world:find_all_by_tag("enemy")) do
        if enemy.isValid and distance_squared(x, y, enemy.pos.x, enemy.pos.y) < minDistanceSq then
            return true
        end
    end

    return false
end

---@param baseX number
---@param baseY number
---@param nx number
---@param ny number
---@param occupiedPositions vec2[]
---@return vec2
function EnemySpawner:find_spawn_position(baseX, baseY, nx, ny, occupiedPositions)
    local rowSpacing = 18
    local maxRows = 8
    local minDistanceSq = rowSpacing * rowSpacing

    for row = 0, maxRows do
        local x = baseX + nx * rowSpacing * row
        local y = baseY + ny * rowSpacing * row
        if not self:is_position_occupied(x, y, occupiedPositions, minDistanceSq) then
            return vec2(x, y)
        end
    end

    return vec2(baseX + nx * rowSpacing * maxRows, baseY + ny * rowSpacing * maxRows)
end

---@param enemyCount? integer
---@param waveNumber? integer
---@return integer
function EnemySpawner:spawnWave(enemyCount, waveNumber)
    enemyCount = enemyCount or 1
    waveNumber = waveNumber or 1

    local spawned = 0
    local tx, ty, nx, ny = self:get_spawn_axes()
    local occupiedPositions = {}

    local spread = 18
    local enemySpeed = 100 + math.min(waveNumber - 1, 10) * 8
    local spawnInset = 14
    local enemyRotation = 0
    if nx ~= 0 or ny ~= 0 then
        enemyRotation = math.atan2(ny, nx)
    end

    for i = 1, enemyCount do
        local offset = (i - (enemyCount + 1) / 2) * spread
        local baseX = self.pos.x + tx * offset + nx * spawnInset
        local baseY = self.pos.y + ty * offset + ny * spawnInset
        local spawnPos = self:find_spawn_position(baseX, baseY, nx, ny, occupiedPositions)
        table.insert(occupiedPositions, spawnPos)
        local enemyType = self:next_enemy_type_for_wave(waveNumber)
        self:spawn(Enemy(spawnPos, enemyRotation, vec2(1.5, 1.5), enemySpeed, {
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
