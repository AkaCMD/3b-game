local Component = require("src.component")

CooldownAction = class({
    name = "CooldownAction",
    extends = Component,
    default_tostring = true,
})

---@param options table
function CooldownAction:new(options)
    options = options or {}
    self:super(options)
    self.cooldown = options.cooldown or 0.5
    self.startReady = options.start_ready ~= false
    self.elapsed = self.startReady and self.cooldown or 0
    self.get_cooldown = options.get_cooldown
    self.should_activate = options.should_activate or options.should_trigger or function()
        return true
    end
    self.perform = assert(options.perform or options.action, "CooldownAction requires perform callback")
    self.after_perform = options.after_perform
end

---@param _entity Entity
function CooldownAction:reset(_entity)
    self.elapsed = self.startReady and self.cooldown or 0
end

---@param entity Entity
---@param dt number
---@param context? table
function CooldownAction:update(entity, dt, context)
    self.elapsed = self.elapsed + dt

    local cooldown = self.cooldown
    if self.get_cooldown then
        cooldown = self.get_cooldown(entity, cooldown, context, self) or cooldown
    end
    cooldown = math.max(0, cooldown or 0)

    if cooldown > 0 and self.elapsed < cooldown then
        return
    end

    if self.should_activate and not self.should_activate(entity, context, self) then
        return
    end

    local performed = self.perform(entity, context, self)
    if performed == false then
        return
    end

    self.elapsed = 0
    if self.after_perform then
        self.after_perform(entity, context, self, performed)
    end
end

return CooldownAction
