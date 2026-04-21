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

PALETTE = {
    white = {1, 1, 1, 1},
    red = {1, 0, 0, 1},
    green = {0, 1, 0, 1},
}

logger = logger or { info = function() end, draw = function() end }
Sfx_portal = Sfx_portal or {}
Sfx_pickup = Sfx_pickup or {}
Sfx_hurt = Sfx_hurt or {}
Sfx_explosion = Sfx_explosion or {}
Sfx_small_hit = Sfx_small_hit or {}
Sfx_big_explosion = Sfx_big_explosion or {}
BloodBatch = BloodBatch or { add = function() end, clear = function() end }
SCREEN_WIDTH = SCREEN_WIDTH or 720
SCREEN_HEIGHT = SCREEN_HEIGHT or 720

return true
