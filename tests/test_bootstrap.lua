package.path = table.concat({
    "./?.lua",
    "./?/init.lua",
    package.path,
}, ";")

love = love or {
    audio = { play = function() end },
    graphics = { setColor = function() end, line = function() end, circle = function() end, draw = function() end, polygon = function() end },
    keyboard = { isDown = function() return false end },
    mouse = { getPosition = function() return 0, 0 end, getX = function() return 0 end, getY = function() return 0 end, isDown = function() return false end },
    timer = { getTime = function() return 0 end },
    system = { getOS = function() return "Linux" end },
    event = { quit = function() end },
}

require("lib.batteries"):export()
Mathx = Batteries.mathx

return true
