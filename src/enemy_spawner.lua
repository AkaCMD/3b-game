local RepeatingTimer = require("src.components.repeating_timer")

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
    self.pos = pos or vec2(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)
    self.hasCollision = false
    self:set_tag("enemy_spawner")
    self:add_component("spawn_timer", RepeatingTimer(spawnTime or 6.0, function(entity)
        entity:spawnWave()
    end))
end

function EnemySpawner:update(dt, context)
    Entity.update(self, dt, context)
end

function EnemySpawner:spawnWave()
    self:spawn(Enemy(vec2(self.pos.x, self.pos.y), 0, vec2(1.5, 1.5), 100))
end

function EnemySpawner:draw()
    love.graphics.setColor(PALETTE.red)
    love.graphics.circle("fill", self.pos.x, self.pos.y, 8)
    love.graphics.setColor(1, 1, 1, 1)
end
