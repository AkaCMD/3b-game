local Geometry = require("src.geometry")

EdgePortal = class({
    name = "EdgePortal",
    default_tostring = true,
})

function EdgePortal:new()
    self.targetEdge = nil
end

function EdgePortal:set_target(targetEdge)
    self.targetEdge = targetEdge
end

function EdgePortal:on_collide(entity, other)
    if other:has_tag("player") then
        logger.info("Portal")
        self:teleport(entity, other)
        love.audio.play(Sfx_portal)
        return
    end

    if other:has_tag("player_bullet") then
        if other.canWarpEdges then
            self:teleport(entity, other)
        else
            other:free()
        end
        return
    end

    if other:has_tag("enemy_bullet") then
        other:free()
    end
end

function EdgePortal:teleport(entity, target)
    if not self.targetEdge then
        return
    end

    local x, y = Geometry.portal_exit(
        target.pos.x,
        target.pos.y,
        entity.startPos.x,
        entity.startPos.y,
        entity.endPos.x,
        entity.endPos.y,
        self.targetEdge.startPos.x,
        self.targetEdge.startPos.y,
        self.targetEdge.endPos.x,
        self.targetEdge.endPos.y,
        8
    )
    target.pos = vec2(x, y)
end

return EdgePortal
