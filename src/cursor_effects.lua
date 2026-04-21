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
    x = x or 0
    y = y or 0

    return {
        render_x = x,
        render_y = y,
        target_x = x,
        target_y = y,
        offset_x = 0,
        offset_y = 0,
        rotation = 0,
        scale_x = 1,
        scale_y = 1,
    }
end

function CursorEffects.update_state(state, target_x, target_y, dt)
    dt = math.max(dt or 0, 0)

    local prev_target_x = state.target_x or target_x
    state.target_x = target_x
    state.target_y = target_y

    state.render_x = target_x
    state.render_y = target_y
    state.offset_x = 0
    state.offset_y = 0
    state.scale_x = 1
    state.scale_y = 1

    local horizontal_speed = dt > 0 and (target_x - prev_target_x) / dt or 0
    local sway_target = clamp(horizontal_speed * 0.00009, math.rad(-14), math.rad(14))
    state.rotation = exp_lerp(state.rotation, sway_target, 18, dt)

    return state
end

return CursorEffects
