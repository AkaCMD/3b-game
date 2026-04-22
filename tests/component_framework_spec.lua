require("tests.test_bootstrap")

require("src.entity")
require("src.player")
local Component = require("src.component")
local LookAtTarget = require("src.components.look_at_target")

local T = require("tests.helpers.testlib")

local OrderComponent = class({
    name = "OrderComponent",
    extends = Component,
    default_tostring = true,
})

function OrderComponent:new(label, order, options)
    options = options or {}
    self:super(options)
    self.label = label
    self.order = order
    self.updateCalls = 0
end

function OrderComponent:update()
    self.updateCalls = self.updateCalls + 1
    table.insert(self.order, self.label)
end

return {
    {
        name = "Entity 会按组件 priority 顺序执行 update",
        run = function()
            local entity = Entity(vec2(0, 0), vec2(1, 1))
            local order = {}

            entity:add_component("late", OrderComponent("late", order, { priority = 10 }))
            entity:add_component("early", OrderComponent("early", order, { priority = -10 }))

            entity:update(0.016, {})

            T.assert_equal(order[1], "early")
            T.assert_equal(order[2], "late")
        end,
    },
    {
        name = "Entity 会校验组件依赖",
        run = function()
            local entity = Entity(vec2(0, 0), vec2(1, 1))
            local ok, err = pcall(function()
                entity:add_component("needs_other", OrderComponent("needs", {}, {
                    requires = { "other_component" },
                }))
            end)

            T.assert_true(not ok)
            T.assert_true(string.find(err, "requires missing component", 1, true) ~= nil)
        end,
    },
    {
        name = "Entity 可启停组件",
        run = function()
            local entity = Entity(vec2(0, 0), vec2(1, 1))
            local order = {}
            local component = OrderComponent("toggle", order)
            entity:add_component("toggle", component)

            entity:enable_component("toggle", false)
            entity:update(0.016, {})
            T.assert_equal(component.updateCalls, 0)

            entity:enable_component("toggle", true)
            entity:update(0.016, {})
            T.assert_equal(component.updateCalls, 1)
        end,
    },
    {
        name = "LookAtTarget 支持回调直接返回 x y",
        run = function()
            local entity = Entity(vec2(10, 10), vec2(1, 1))
            entity:add_component("look", LookAtTarget({
                get_target_position = function()
                    return 30, 10
                end,
            }))

            entity:update(0.016, {})

            T.assert_close(entity.rotation, 0, 1e-6)
        end,
    },
    {
        name = "Player 会跟随鼠标位置旋转",
        run = function()
            local originalGetPosition = love.mouse.getPosition
            love.mouse.getPosition = function()
                return 30, 10
            end

            local player = Player(vec2(10, 10), vec2(1, 1))
            player:update(0.016, {})

            love.mouse.getPosition = originalGetPosition
            T.assert_close(player.rotation, math.pi / 2, 1e-6)
        end,
    },
}
