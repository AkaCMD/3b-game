require("tests.test_bootstrap")

local TestLib = require("tests.helpers.testlib")

local spec_modules = {
    "tests.geometry_spec",
    "tests.entity_component_spec",
    "tests.edge_component_spec",
    "tests.world_spec",
    "tests.upgrade_definitions_spec",
    "tests.wave_manager_spec",
}

local total = 0
for _, module_name in ipairs(spec_modules) do
    local cases = require(module_name)
    total = total + TestLib.run_cases(cases)
end

print(("tests passed: %d"):format(total))
