KeyboardMove = class({
    name = "KeyboardMove",
    default_tostring = true,
})

function KeyboardMove:new(speed, controls)
    self.speed = speed or 200
    self.controls = controls or {
        left = "a",
        right = "d",
        up = "w",
        down = "s",
    }
end

function KeyboardMove:update(entity, dt)
    local dir = vec2(0, 0)
    if love.keyboard.isDown(self.controls.left) then dir.x = dir.x - 1 end
    if love.keyboard.isDown(self.controls.right) then dir.x = dir.x + 1 end
    if love.keyboard.isDown(self.controls.up) then dir.y = dir.y - 1 end
    if love.keyboard.isDown(self.controls.down) then dir.y = dir.y + 1 end

    if dir:length_squared() > 0 then
        dir:normalise_inplace()
        local speed = self.speed
        if entity.get_move_speed then
            speed = entity:get_move_speed(speed)
        end
        entity.pos:fused_multiply_add_inplace(dir, speed * dt)
    end
end

return KeyboardMove
