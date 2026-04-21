require("tests.test_bootstrap")

require("src.entity")
require("src.world")

local T = require("tests.helpers.testlib")

local FakeEntity = class({
    name = "FakeEntity",
    extends = Entity,
    default_tostring = true,
})

function FakeEntity:new(valid)
    self:super(vec2(0, 0), vec2(1, 1))
    self.isValid = valid
    self.freeCalls = 0
    self.updateCalls = 0
end

function FakeEntity:update()
    self.updateCalls = self.updateCalls + 1
end

function FakeEntity:free()
    self.freeCalls = self.freeCalls + 1
    self.isValid = false
end

return {
    {
        name = "add_entity 会把实体加入世界",
        run = function()
            local world = World()
            local entity = FakeEntity(true)

            world:add_entity(entity)

            T.assert_equal(#world.entities, 1)
            T.assert_true(world.entities[1] == entity)
        end,
    },
    {
        name = "remove_entity 会释放仍然有效的实体",
        run = function()
            local world = World()
            local entity = FakeEntity(true)
            world:add_entity(entity)

            world:remove_entity(1)

            T.assert_equal(entity.freeCalls, 1)
            T.assert_equal(#world.entities, 0)
        end,
    },
    {
        name = "update 清理无效实体时不会重复调用 free",
        run = function()
            local world = World()
            local entity = FakeEntity(false)
            world:add_entity(entity)

            world:update(0.016)

            T.assert_equal(entity.freeCalls, 0)
            T.assert_equal(#world.entities, 0)
        end,
    },
    {
        name = "update 会更新有效实体",
        run = function()
            local world = World()
            local entity = FakeEntity(true)
            world:add_entity(entity)

            world:update(0.016)

            T.assert_equal(entity.updateCalls, 1)
        end,
    },
}
