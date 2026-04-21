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
    self.baseDelay = options.base_delay or 1.5
    self.timeUntilNextWave = options.initial_delay or self.baseDelay
    self.upgradeEvery = options.upgrade_every or 3
    self.waveScaleInterval = options.wave_scale_interval or 2
    self.onWaveStarted = options.on_wave_started
    self.onWaveCleared = options.on_wave_cleared
    self.onUpgradeReady = options.on_upgrade_ready
end

function WaveManager:update(dt)
    if self.awaitingUpgradeSelection then
        return
    end

    if self.waveActive then
        if self:get_alive_enemy_count() == 0 then
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
    return #self.world:find_all_by_tag("enemy")
end

function WaveManager:get_spawners()
    return self.world:find_all_by_tag("enemy_spawner")
end

function WaveManager:get_enemies_per_spawner(waveNumber)
    waveNumber = waveNumber or (self.currentWave + 1)
    return 1 + math.floor((waveNumber - 1) / self.waveScaleInterval)
end

function WaveManager:schedule_next_wave(delay)
    self.timeUntilNextWave = delay or self.baseDelay
end

function WaveManager:spawn_next_wave()
    local spawners = self:get_spawners()
    if #spawners == 0 then
        self:schedule_next_wave(0.5)
        return false
    end

    self.currentWave = self.currentWave + 1
    local enemiesPerSpawner = self:get_enemies_per_spawner(self.currentWave)
    local spawned = 0

    for _, spawner in ipairs(spawners) do
        spawned = spawned + (spawner:spawnWave(enemiesPerSpawner, self.currentWave) or 0)
    end

    if spawned <= 0 then
        self.currentWave = self.currentWave - 1
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
        return "请选择一项升级"
    end

    if self.upgradeEvery <= 0 then
        return ""
    end

    local progress = self.clearedWaves % self.upgradeEvery
    local remaining = self.upgradeEvery - progress
    if remaining == self.upgradeEvery then
        remaining = self.upgradeEvery
    end

    return ("再完成 %d 波获得升级"):format(remaining)
end

return WaveManager
