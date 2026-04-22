local GameplayEffects = require("src.gameplay_effects")

return function(app)
    local scene = {}
    local timerUI = Text(app.timer or 0, 30, PALETTE.red, SCREEN_WIDTH/2, 50, true, 0)
    local waveStatusUI = Text("", 18, PALETTE.green, SCREEN_WIDTH/2, 88, true, 0)
    local upgradeHintUI = Text("", 14, PALETTE.white, SCREEN_WIDTH/2, 114, true, 0)
    local angle = 0

    local function is_upgrade_pause_active()
        return app.powerupUI and app.powerupUI:isActive()
    end

    function scene:enter()
        love.mouse.setVisible(false)
        app.powerupUI = PowerupScreenUI(app.player, function()
            if app.waveManager then
                app.waveManager:complete_upgrade_selection()
            end
        end)
        app.waveManager = WaveManager(World, {
            initial_delay = 1.0,
            upgrade_every = 3,
            max_active_enemies = 12,
            max_spawn_per_step = 3,
            on_upgrade_ready = function()
                return app.powerupUI and app.powerupUI:offer_random_upgrades() or false
            end,
        })
    end

    function scene:draw()
        app.effect(function()
            if GameplayEffects.should_draw_shake(app.shake.t, app.shake.duration, is_upgrade_pause_active()) then
                local dx = love.math.random(-app.shake.magnitude, app.shake.magnitude)
                local dy = love.math.random(-app.shake.magnitude, app.shake.magnitude)
                love.graphics.translate(dx, dy)
            end

            love.graphics.setLineWidth(2)
            love.graphics.setColor(PALETTE.white)

            app.level:draw()

            love.graphics.draw(BloodBatch)
            for _, entity in ipairs(World.entities) do
                entity:draw()
                entity:drawHitbox()
            end

            app.drawHeartShapes(vec2(110, SCREEN_HEIGHT - 90))
            timerUI:draw()
            waveStatusUI:draw()
            upgradeHintUI:draw()
        end)

        if app.powerupUI then
            app.powerupUI:draw()
        end
    end

    function scene:update(dt)
        for i = #app.timers, 1, -1 do
            app.timers[i]:update(dt)
        end

        if app.shake.t < app.shake.duration then
            app.shake.t = GameplayEffects.advance_shake_time(app.shake.t, app.shake.duration, dt)
        end

        if is_upgrade_pause_active() then
            if app.powerupUI then
                app.powerupUI:update(dt)
            end
            return
        end

        if app.player.health <= 0 then
            app.sceneManager:enter(app.state.gameover)
        end

        app.timer = app.timer + dt
        angle = angle + dt * 0.8

        app.level:update(dt)
        World:update(dt, app.level)
        World:check_collisions()

        if app.waveManager then
            app.waveManager:update(dt)
            waveStatusUI.content = app.waveManager:get_wave_text()
            upgradeHintUI.content = app.waveManager:get_upgrade_progress_text()
        end

        timerUI.content = app.formatTimer(app.timer)

        if app.powerupUI then
            app.powerupUI:update(dt)
        end
    end

    function scene:mousereleased(x, y, button)
        if app.powerupUI and app.powerupUI:isActive() then
            app.powerupUI:mousereleased(x, y, button)
            return
        end
    end

    function scene:keypressed(key)
        if key == "escape" then
            app.sceneManager:push(app.state.pause)
        end
        app.player:keypressed(key)

        if key == "1" then
            app.level:clearEdges()
            app.level:randomizeEdges()
        end
        if key == "2" then
            app.level:shrinkLevel()
        end

        if key == "u" and app.powerupUI then
            local shown = app.powerupUI:offer_random_upgrades()
            if app.waveManager then
                app.waveManager.awaitingUpgradeSelection = shown == true
            end
        end
    end

    return scene
end
