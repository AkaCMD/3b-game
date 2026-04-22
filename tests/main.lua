package.path = table.concat({
    "../?.lua",
    "../?/init.lua",
    "./?.lua",
    "./?/init.lua",
    package.path,
}, ";")

local function run_tests()
    require("tests.run")
    print("love test runner done")
    love.event.quit(0)
end

function love.load()
    local ok, err = xpcall(run_tests, debug.traceback)
    if ok then
        return
    end

    io.stderr:write(err .. "\n")
    error(err)
end
