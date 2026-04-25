local Geometry = {}

function Geometry.lerp_point(ax, ay, bx, by, t)
    return ax + (bx - ax) * t, ay + (by - ay) * t
end

function Geometry.segment_length(ax, ay, bx, by)
    local dx = bx - ax
    local dy = by - ay
    return math.sqrt(dx * dx + dy * dy)
end

function Geometry.segment_midpoint(ax, ay, bx, by)
    return (ax + bx) / 2, (ay + by) / 2
end

function Geometry.segment_hitbox(ax, ay, bx, by, thickness)
    thickness = thickness or 5
    local length = Geometry.segment_length(ax, ay, bx, by)
    if math.abs(bx - ax) > math.abs(by - ay) then
        return length, thickness
    end
    return thickness, length
end

function Geometry.project_ratio_on_segment(px, py, ax, ay, bx, by)
    local vx, vy = bx - ax, by - ay
    local wx, wy = px - ax, py - ay
    local denom = vx * vx + vy * vy
    if denom == 0 then
        return 0
    end
    local t = (wx * vx + wy * vy) / denom
    return Mathx.clamp(t, 0, 1)
end

function Geometry.segment_normal(ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local len = Geometry.segment_length(ax, ay, bx, by)
    if len == 0 then
        return 0, 0
    end
    return -dy / len, dx / len
end

function Geometry.segment_normal_towards_point(ax, ay, bx, by, px, py)
    local nx, ny = Geometry.segment_normal(ax, ay, bx, by)
    local mx, my = Geometry.segment_midpoint(ax, ay, bx, by)
    local toPointX = px - mx
    local toPointY = py - my

    if (nx * toPointX + ny * toPointY) < 0 then
        nx = -nx
        ny = -ny
    end

    return nx, ny
end

function Geometry.portal_exit(px, py, source_ax, source_ay, source_bx, source_by, target_ax, target_ay, target_bx, target_by, offset)
    local t = Geometry.project_ratio_on_segment(px, py, source_ax, source_ay, source_bx, source_by)
    local dest_x, dest_y = Geometry.lerp_point(target_ax, target_ay, target_bx, target_by, t)
    local nx, ny = Geometry.segment_normal(target_ax, target_ay, target_bx, target_by)
    offset = offset or 0
    return dest_x + nx * offset, dest_y + ny * offset, t
end

function Geometry.point_within(px, py, x, y, w, h)
    return px > x and px < x + w and py > y and py < y + h
end

function Geometry.rectangle_corners(cx, cy, hsx, hsy, offset)
    offset = offset or 0
    return {
        { x = cx - hsx - offset, y = cy - hsy - offset },
        { x = cx + hsx + offset, y = cy - hsy - offset },
        { x = cx + hsx + offset, y = cy + hsy + offset },
        { x = cx - hsx - offset, y = cy + hsy + offset },
    }
end

function Geometry.apply_edge_geometry(edge, thickness)
    local start_pos = edge.startPos
    local end_pos = edge.endPos
    local x, y = Geometry.segment_midpoint(start_pos.x, start_pos.y, end_pos.x, end_pos.y)
    local hitbox_w, hitbox_h = Geometry.segment_hitbox(start_pos.x, start_pos.y, end_pos.x, end_pos.y, thickness)

    edge.pos = vec2(x, y)
    edge.length = Geometry.segment_length(start_pos.x, start_pos.y, end_pos.x, end_pos.y)
    edge.hitbox = vec2(hitbox_w, hitbox_h)
    edge.hs = edge.hitbox:pooled_copy():scalar_mul_inplace(0.5)

    return edge
end

return Geometry
