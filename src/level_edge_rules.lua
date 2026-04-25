local LevelEdgeRules = {}

LevelEdgeRules.EdgeKind = {
    Normal = "normal",
    SpawnEnemy = "spawn_enemy",
    Portal = "portal",
}

---@param min integer
---@param max integer
---@return integer
local function default_random_int(min, max)
    return math.random(min, max)
end

local function default_random_float()
    return math.random()
end

---@param list table
---@param index integer
---@return any
local function remove_at(list, index)
    local value = list[index]
    table.remove(list, index)
    return value
end

---@param list table
---@return table
local function clone_list(list)
    local copy = {}
    for i, value in ipairs(list) do
        copy[i] = value
    end
    return copy
end

---@param random_int? fun(min: integer, max: integer): integer
---@param random_float? fun(): number
---@return table
function LevelEdgeRules.build_layout(random_int, random_float)
    random_int = random_int or default_random_int
    random_float = random_float or default_random_float

    local available_positions = {1, 2, 3, 4}
    local layout = {}

    if random_float() < 0.7 then
        local portal_positions = {}
        for i = 1, 2 do
            local random_index = random_int(1, #available_positions)
            portal_positions[i] = remove_at(available_positions, random_index)
        end

        local portal_a = portal_positions[1]
        local portal_b = portal_positions[2]
        layout[portal_a] = { kind = LevelEdgeRules.EdgeKind.Portal, target = portal_b }
        layout[portal_b] = { kind = LevelEdgeRules.EdgeKind.Portal, target = portal_a }
    end

    local enemy_index = random_int(1, #available_positions)
    local enemy_position = remove_at(available_positions, enemy_index)
    layout[enemy_position] = { kind = LevelEdgeRules.EdgeKind.SpawnEnemy }

    local fill_types = {
        LevelEdgeRules.EdgeKind.Normal,
        LevelEdgeRules.EdgeKind.SpawnEnemy,
    }

    for _, position in ipairs(available_positions) do
        local type_index = random_int(1, #fill_types)
        layout[position] = { kind = fill_types[type_index] }
    end

    return layout
end

---@param layout table
---@param kind string
---@return integer
function LevelEdgeRules.count_kind(layout, kind)
    local count = 0
    for _, edge in pairs(layout) do
        if edge.kind == kind then
            count = count + 1
        end
    end
    return count
end

---@param layout table
---@return integer[]
function LevelEdgeRules.list_positions(layout)
    local positions = {}
    for position in pairs(layout) do
        table.insert(positions, position)
    end
    table.sort(positions)
    return positions
end

---@param layout table
---@return table
function LevelEdgeRules.copy_layout(layout)
    local copy = {}
    for position, edge in pairs(layout) do
        copy[position] = clone_list(edge)
        copy[position].kind = edge.kind
        copy[position].target = edge.target
    end
    return copy
end

return LevelEdgeRules
