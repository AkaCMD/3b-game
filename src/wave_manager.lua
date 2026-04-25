WaveManager = class({
    name = "WaveManager",
    default_tostring = true,
})

function WaveManager:new(world, options)
    options = options or {}
    self.world = assert(world, "WaveManager requires world")
    self.currentWave = 0
    self.clearedWaves = 0
    self.waveActive = false
    self.awaitingUpgradeSelection = false
    self.pendingEnemiesToSpawn = 0
    self.baseDelay = options.base_delay or 1.5
    self.timeUntilNextWave = options.initial_delay or self.baseDelay
    self.upgradeEvery = options.upgrade_every or 3
    self.waveScaleInterval = options.wave_scale_interval or 2
    self.maxActiveEnemies = options.max_active_enemies or 12
    self.maxSpawnPerStep = options.max_spawn_per_step or 3
    self.onWaveStarted = options.on_wave_started
    self.onWaveCleared = options.on_wave_cleared
    self.onUpgradeReady = options.on_upgrade_ready
end

function WaveManager:update(dt)
    if self.awaitingUpgradeSelection then
        return
    end

    if self.waveActive then
        local aliveEnemies = self:get_alive_enemy_count()
        if self.pendingEnemiesToSpawn > 0 then
            local spawned = self:spawn_pending_enemies(aliveEnemies)
            if spawned > 0 then
                aliveEnemies = self:get_alive_enemy_count()
            elseif aliveEnemies == 0 and #self:get_spawners() == 0 then
                self.pendingEnemiesToSpawn = 0
            end
        end

        if self.pendingEnemiesToSpawn <= 0 and aliveEnemies == 0 then
            self.waveActive = false
            self.clearedWaves = self.clearedWaves + 1

            if self.onWaveCleared then
                self.onWaveCleared(self, self.currentWave, self.clearedWaves)
            end

            if self.upgradeEvery > 0 and self.clearedWaves % self.upgradeEvery == 0 then
                self.awaitingUpgradeSelection = true
                local shown = false
                if self.onUpgradeReady then
                    shown = self.onUpgradeReady(self, self.currentWave, self.clearedWaves) == true
                end
                if not shown then
                    self.awaitingUpgradeSelection = false
                    self:schedule_next_wave()
                end
            else
                self:schedule_next_wave()
            end
        end
        return
    end

    self.timeUntilNextWave = self.timeUntilNextWave - dt
    if self.timeUntilNextWave <= 0 then
        self:spawn_next_wave()
    end
end

function WaveManager:get_alive_enemy_count()
    if self.world.get_tag_count then
        return self.world:get_tag_count("enemy")
    end
    return #self.world:find_all_by_tag("enemy")
end

function WaveManager:get_spawners()
    return self.world:find_all_by_tag("enemy_spawner")
end

function WaveManager:get_enemies_per_spawner(waveNumber)
    waveNumber = waveNumber or (self.currentWave + 1)
    return 1 + math.floor((waveNumber - 1) / self.waveScaleInterval)
end

function WaveManager:get_available_enemy_slots(aliveEnemies)
    aliveEnemies = aliveEnemies or self:get_alive_enemy_count()
    if self.maxActiveEnemies == nil or self.maxActiveEnemies <= 0 then
        return math.huge
    end
    return math.max(0, self.maxActiveEnemies - aliveEnemies)
end

function WaveManager:schedule_next_wave(delay)
    self.timeUntilNextWave = delay or self.baseDelay
end

function WaveManager:spawn_pending_enemies(aliveEnemies)
    if self.pendingEnemiesToSpawn <= 0 then
        return 0
    end

    local spawners = self:get_spawners()
    if #spawners == 0 then
        return 0
    end

    local availableSlots = self:get_available_enemy_slots(aliveEnemies)
    if availableSlots <= 0 then
        return 0
    end

    local maxSpawnPerStep = self.maxSpawnPerStep
    if maxSpawnPerStep == nil or maxSpawnPerStep <= 0 then
        maxSpawnPerStep = math.huge
    end

    local toSpawn = math.min(self.pendingEnemiesToSpawn, availableSlots, maxSpawnPerStep)
    local spawned = 0

    while toSpawn > 0 do
        local spawnedThisPass = 0
        for _, spawner in ipairs(spawners) do
            if toSpawn <= 0 then
                break
            end

            local count = spawner:spawnWave(1, self.currentWave) or 0
            if count > 0 then
                spawned = spawned + count
                spawnedThisPass = spawnedThisPass + count
                self.pendingEnemiesToSpawn = math.max(0, self.pendingEnemiesToSpawn - count)
                toSpawn = math.max(0, toSpawn - count)
            end
        end

        if spawnedThisPass <= 0 then
            break
        end
    end

    return spawned
end

function WaveManager:spawn_next_wave()
    local spawners = self:get_spawners()
    if #spawners == 0 then
        self:schedule_next_wave(0.5)
        return false
    end

    self.currentWave = self.currentWave + 1
    local enemiesPerSpawner = self:get_enemies_per_spawner(self.currentWave)
    self.pendingEnemiesToSpawn = enemiesPerSpawner * #spawners
    local spawned = self:spawn_pending_enemies(self:get_alive_enemy_count())

    if spawned <= 0 then
        self.currentWave = self.currentWave - 1
        self.pendingEnemiesToSpawn = 0
        self:schedule_next_wave(0.5)
        return false
    end

    self.waveActive = true
    self.timeUntilNextWave = 0

    if self.onWaveStarted then
        self.onWaveStarted(self, self.currentWave, spawned, enemiesPerSpawner)
    end

    return true
end

function WaveManager:complete_upgrade_selection()
    self.awaitingUpgradeSelection = false
    self:schedule_next_wave()
end

function WaveManager:get_wave_text()
    local displayWave = self.currentWave
    if not self.waveActive and not self.awaitingUpgradeSelection then
        displayWave = self.currentWave + 1
    end
    return ("波次 %d"):format(math.max(displayWave, 1))
end

function WaveManager:get_upgrade_progress_text()
    if self.awaitingUpgradeSelection then
        return "Choose an upgrade"
    end

    if self.upgradeEvery <= 0 then
        return ""
    end

    local progress = self.clearedWaves % self.upgradeEvery
    local remaining = self.upgradeEvery - progress
    if remaining == self.upgradeEvery then
        remaining = self.upgradeEvery
    end

    return ("%d more waves until upgrade"):format(remaining)
end

return WaveManager
