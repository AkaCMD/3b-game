Component = class({
    name = "Component",
    default_tostring = true,
})

local function clone_list(values)
    if values == nil then
        return {}
    end

    if type(values) == "string" then
        return { values }
    end

    local result = {}
    for i, value in ipairs(values) do
        result[i] = value
    end
    return result
end

function Component:new(options)
    options = options or {}
    self.id = options.id or self.id or self.name
    self.priority = options.priority or self.priority or 0
    if options.enabled == nil then
        if self.enabled == nil then
            self.enabled = true
        end
    else
        self.enabled = options.enabled
    end
    self.requires = clone_list(options.requires or self.requires)
    self.category = options.category or self.category or "generic"
    self.debug_name = options.debug_name or self.debug_name or self.id or self.name
end

function Component:set_enabled(enabled)
    self.enabled = enabled ~= false
    return self
end

function Component:is_enabled()
    return self.enabled ~= false
end

function Component:validate(_entity)
    return true
end

function Component:reset(_entity)
end

return Component
