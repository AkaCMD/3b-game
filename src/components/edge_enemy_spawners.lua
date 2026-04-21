local Geometry = require("src.geometry")

EdgeEnemySpawners = class({
    name = "EdgeEnemySpawners",
    default_tostring = true,
})

function EdgeEnemySpawners:new(count)
    self.count = count or 3
    self.spawners = {}
end

function EdgeEnemySpawners:init(entity)
    entity.enemySpawners = self.spawners
end

function EdgeEnemySpawners:on_added_to_world(entity)
    self:rebuild(entity)
end

function EdgeEnemySpawners:on_removed_from_world(entity)
    self:clear(entity)
end

function EdgeEnemySpawners:on_geometry_changed(entity)
    if entity.world then
        self:rebuild(entity)
    end
end

function EdgeEnemySpawners:get_spawners()
    return self.spawners
end

function EdgeEnemySpawners:clear(entity)
    for _, spawner in ipairs(self.spawners) do
        spawner.isValid = false
    end
    self.spawners = {}
    entity.enemySpawners = self.spawners
end

function EdgeEnemySpawners:rebuild(entity)
    self:clear(entity)

    local interval = entity.length / self.count
    for i = 1, self.count do
        local x, y = Geometry.lerp_point(
            entity.startPos.x,
            entity.startPos.y,
            entity.endPos.x,
            entity.endPos.y,
            (interval * i - interval / 2) / entity.length
        )
        local spawner = EnemySpawner(vec2(x, y))
        table.insert(self.spawners, spawner)
        entity:spawn(spawner)
    end

    entity.enemySpawners = self.spawners
end

return EdgeEnemySpawners
