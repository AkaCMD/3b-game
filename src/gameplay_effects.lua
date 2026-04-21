local GameplayEffects = {}

function GameplayEffects.advance_shake_time(elapsed, duration, dt)
    if elapsed >= duration then
        return elapsed
    end

    return elapsed + dt
end

function GameplayEffects.should_draw_shake(elapsed, duration, isUpgradePaused)
    if isUpgradePaused then
        return false
    end

    return elapsed < duration
end

return GameplayEffects
