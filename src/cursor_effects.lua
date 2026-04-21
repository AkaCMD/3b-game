local CursorEffects = {}

local function clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function exp_lerp(current, target, sharpness, dt)
    return current + (target - current) * (1 - math.exp(-sharpness * dt))
end

function CursorEffects.new_state(x, y)
    return {
        render_x = x or 0,
        render_y = y or 0,
        target_x = x or 0,
        target_y = y or 0,
        offset_x = 0,
        offset_y = 0,
        rotation = 0,
        scale_x = 1,
        scale_y = 1,
        pulse = 0,
        stretch = 0,
        tilt = 0,
        speed = 0,
        fire_cooldown = 0,
        time = 0,
    }
end

function CursorEffects.update_state(state, target_x, target_y, dt, is_firing)
    dt = math.max(dt or 0, 0)
    state.time = state.time + dt
    state.target_x = target_x
    state.target_y = target_y

    local dx = target_x - state.render_x
    local dy = target_y - state.render_y
    local vx = dt > 0 and dx / dt or 0
    local vy = dt > 0 and dy / dt or 0
    local speed = math.sqrt(vx * vx + vy * vy)

    state.render_x = exp_lerp(state.render_x, target_x, 30, dt)
    state.render_y = exp_lerp(state.render_y, target_y, 30, dt)
    state.speed = speed

    local tilt_target = clamp(vx * 0.00008, math.rad(-16), math.rad(16))
    local stretch_target = clamp(speed / 20000, 0, 0.18)
    state.tilt = exp_lerp(state.tilt, tilt_target, 18, dt)
    state.stretch = exp_lerp(state.stretch, stretch_target, 14, dt)

    if is_firing then
        state.fire_cooldown = state.fire_cooldown - dt
        if state.fire_cooldown <= 0 then
            state.pulse = math.min(1.2, state.pulse + 0.55)
            state.fire_cooldown = 0.06
        end
    else
        state.fire_cooldown = 0
    end

    state.pulse = math.max(0, state.pulse - dt * 2.6)

    local tremor = state.pulse * state.pulse
    state.offset_x = clamp(-vx * 0.0015 + math.sin(state.time * 90) * tremor * 1.8, -6, 6)
    state.offset_y = clamp(-vy * 0.0015 + math.cos(state.time * 72) * tremor * 1.4, -6, 6)
    state.rotation = state.tilt + math.sin(state.time * 26) * state.pulse * 0.06

    local breathe = 1 + math.sin(state.time * 8) * 0.02
    local squash = state.stretch + state.pulse * 0.12
    state.scale_x = breathe * (1 + squash)
    state.scale_y = breathe * math.max(0.72, 1 - squash * 0.65 + state.pulse * 0.04)

    return state
end

return CursorEffects
