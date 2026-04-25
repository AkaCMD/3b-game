local TestLib = {}

---@param value any
---@return string
local function format_value(value)
    if type(value) == "table" then
        local ok, pretty = pcall(function()
            return Batteries.pretty.string(value)
        end)
        if ok then
            return pretty
        end
    end
    return tostring(value)
end

---@param value any
---@param message? string
function TestLib.assert_true(value, message)
    if not value then
        error(message or "期望值为真", 2)
    end
end

---@param actual any
---@param expected any
---@param message? string
function TestLib.assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message or ("期望 %s，实际 %s"):format(format_value(expected), format_value(actual)), 2)
    end
end

---@param actual number
---@param expected number
---@param epsilon? number
---@param message? string
function TestLib.assert_close(actual, expected, epsilon, message)
    epsilon = epsilon or 1e-6
    if math.abs(actual - expected) > epsilon then
        error(message or ("期望接近 %s，实际 %s"):format(expected, actual), 2)
    end
end

---@param cases table[]
---@return integer
function TestLib.run_cases(cases)
    local passed = 0
    for _, case in ipairs(cases) do
        case.run()
        passed = passed + 1
    end
    return passed
end

return TestLib
