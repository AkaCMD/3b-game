require("tests.test_bootstrap")

require("src.entity")
require("src.world")
local Damageable = require("src.components.damageable")
local HitTargets = require("src.components.hit_targets")
local Invulnerability = require("src.components.invulnerability")
local PickupOnTouch = require("src.components.pickup_on_touch")

local T = require("tests.helpers.testlib")

local FakeComponent = class({
    name = "FakeComponent",
    default_tostring = true,
})

function FakeComponent:new()
    self.initCalls = 0
    self.updateCalls = 0
    self.collideCalls = 0
    self.lastEntity = nil
    self.lastContext = nil
end

function FakeComponent:init(entity)
    self.initCalls = self.initCalls + 1
    self.lastEntity = entity
end

function FakeComponent:update(entity, dt, context)
    self.updateCalls = self.updateCalls + 1
    self.lastEntity = entity
    self.lastContext = context
end

function FakeComponent:on_collide(entity, other)
    self.collideCalls = self.collideCalls + 1
    self.lastEntity = entity
    self.lastOther = other
end

local SpawnerEntity = class({
    name = "SpawnerEntity",
    extends = Entity,
    default_tostring = true,
})

function SpawnerEntity:new()
    self:super(vec2(0, 0), vec2(1, 1))
    self.spawned = false
end

function SpawnerEntity:update(dt, context)
    if self.spawned then
        return
    end
    self.spawned = true
    self:spawn(Entity(vec2(1, 1), vec2(1, 1)))
end

return {
    {
        name = "Entity 组件会收到 init update 和 on_collide 生命周期",
        run = function()
            local entity = Entity(vec2(0, 0), vec2(1, 1))
            local component = FakeComponent()
            local other = Entity(vec2(0, 0), vec2(1, 1))
            local context = { marker = true }

            entity:add_component("fake", component)
            entity:update(0.016, context)
            entity:onCollide(other)

            T.assert_equal(component.initCalls, 1)
            T.assert_equal(component.updateCalls, 1)
            T.assert_equal(component.collideCalls, 1)
            T.assert_true(component.lastEntity == entity)
            T.assert_true(component.lastContext == context)
            T.assert_true(component.lastOther == other)
        end,
    },
    {
        name = "Damageable 会同步实体生命值并触发受伤回调",
        run = function()
            local entity = Entity(vec2(0, 0), vec2(1, 1))
            local damaged = 0
            entity:add_component("damageable", Damageable({
                health = 3,
                on_damaged = function(_, amount)
                    damaged = damaged + amount
                end,
            }))

            local applied = entity:get_component("damageable"):apply_damage(entity, 1)

            T.assert_true(applied)
            T.assert_equal(entity.health, 2)
            T.assert_equal(damaged, 1)
        end,
    },
    {
        name = "Damageable 可结合 Invulnerability 阻止重复受伤",
        run = function()
            local entity = Entity(vec2(0, 0), vec2(1, 1))
            local invulnerability = Invulnerability(1)
            entity:add_component("invulnerability", invulnerability)
            entity:add_component("damageable", Damageable({
                health = 3,
                invulnerabilityComponent = "invulnerability",
            }))

            invulnerability:trigger(entity)
            local applied = entity:get_component("damageable"):apply_damage(entity, 1)

            T.assert_true(not applied)
            T.assert_equal(entity.health, 3)
        end,
    },
    {
        name = "HitTargets 会按 tag 命中 Damageable 并销毁来源实体",
        run = function()
            local attacker = Entity(vec2(0, 0), vec2(1, 1))
            local target = Entity(vec2(0, 0), vec2(1, 1))
            target:set_tag("enemy")
            target:add_component("damageable", Damageable({ health = 2 }))
            attacker:add_component("hit_targets", HitTargets({
                targetTags = { "enemy" },
                damage = 1,
                destroyOnHit = true,
            }))

            attacker:onCollide(target)

            T.assert_equal(target.health, 1)
            T.assert_true(not attacker.isValid)
        end,
    },
    {
        name = "PickupOnTouch 会对目标执行回调并消费拾取物",
        run = function()
            local item = Entity(vec2(0, 0), vec2(1, 1))
            local playerEntity = Entity(vec2(0, 0), vec2(1, 1))
            playerEntity:set_tag("player")
            playerEntity:add_component("damageable", Damageable({ health = 2, maxHealth = 6 }))
            item:add_component("pickup", PickupOnTouch({
                targetTags = { "player" },
                on_pickup = function(_, other)
                    other:get_component("damageable"):change_health(other, 1)
                end,
            }))

            item:onCollide(playerEntity)

            T.assert_equal(playerEntity.health, 3)
            T.assert_true(not item.isValid)
        end,
    },
    {
        name = "World 会为实体建立 world 引用并支持按 tag 查询",
        run = function()
            local world = World()
            local entity = Entity(vec2(0, 0), vec2(1, 1))
            entity:set_tag("player")

            world:add_entity(entity)

            T.assert_true(entity.world == world)
            T.assert_true(world:find_first_by_tag("player") == entity)
            T.assert_equal(#world:find_all_by_tag("player"), 1)
            T.assert_true(world:get_player() == entity)
        end,
    },
    {
        name = "World 支持通过事件总线通信并在 update 后刷新待添加实体",
        run = function()
            local world = World()
            local spawner = SpawnerEntity()
            local received = false

            world:subscribe("ping", function(payload)
                received = payload.ok == true
            end)
            world:add_entity(spawner)
            world:publish("ping", { ok = true })
            world:update(0.016)

            T.assert_true(received)
            T.assert_equal(#world.entities, 2)
        end,
    },
}
