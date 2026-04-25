package.path = table.concat({
    "./?.lua",
    "./?/init.lua",
    package.path,
}, ";")

love = love or {}
love.audio = love.audio or { play = function() end }
love.graphics = love.graphics or {}
love.graphics.setColor = love.graphics.setColor or function() end
love.graphics.line = love.graphics.line or function() end
love.graphics.circle = love.graphics.circle or function() end
love.graphics.draw = love.graphics.draw or function() end
love.graphics.arc = love.graphics.arc or function() end
love.graphics.polygon = love.graphics.polygon or function() end
love.graphics.rectangle = love.graphics.rectangle or function() end
love.graphics.printf = love.graphics.printf or function() end
love.graphics.print = love.graphics.print or function() end
love.graphics.push = love.graphics.push or function() end
love.graphics.pop = love.graphics.pop or function() end
love.graphics.translate = love.graphics.translate or function() end
love.graphics.rotate = love.graphics.rotate or function() end
love.graphics.scale = love.graphics.scale or function() end
love.graphics.setLineWidth = love.graphics.setLineWidth or function() end
love.graphics.setFont = love.graphics.setFont or function() end
---@param x number
---@param y number
---@return number, number
love.graphics.inverseTransformPoint = love.graphics.inverseTransformPoint or function(x, y) return x, y end
love.keyboard = love.keyboard or {}
love.keyboard.isDown = love.keyboard.isDown or function() return false end
love.keyboard.setTextInput = love.keyboard.setTextInput or function() end
love.mouse = love.mouse or {}
love.mouse.getPosition = love.mouse.getPosition or function() return 0, 0 end
love.mouse.getX = love.mouse.getX or function() return 0 end
love.mouse.getY = love.mouse.getY or function() return 0 end
love.mouse.isDown = love.mouse.isDown or function() return false end
love.mouse.setVisible = love.mouse.setVisible or function() end
love.timer = love.timer or { getTime = function() return 0 end }
love.system = love.system or { getOS = function() return "Linux" end }
love.event = love.event or { quit = function() end }
love.window = love.window or { setTitle = function() end, setMode = function() end }

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
Assets = Assets or {
    fonts = {
        RasterForgeRegular = function()
            return {
                ---@param _ table
                ---@param text string
                ---@return integer, string[]
                getWrap = function(_, text)
                    return #text, { text }
                end,
                getHeight = function()
                    return 16
                end,
                ---@param _ table
                ---@param text string
                ---@return integer
                getWidth = function(_, text)
                    return #text * 8
                end,
            }
        end,
    },
}

return true
