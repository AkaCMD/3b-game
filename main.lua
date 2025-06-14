if arg[2] == "debug" then
    require("lldebugger").start()
end

io.stdout:setvbuf("no")
love.graphics.setDefaultFilter("nearest", "nearest")

batteries = require("lib.batteries"):export()
assets = require("lib.cargo.cargo").init("assets")
moonshine = require("lib.moonshine")
require("src.entity")
require("src.cursor")
require("src.player")
require("src.bullet")
require("src.level")

local entities = {}

local screen_width = 720
local screen_height = 720

local shootCooldown = 0.1
local lastShotTime = 0

local level
local effect

function love.load()
	love.window.setTitle("Bravo! Border Breaker")
	love.window.setMode(screen_width, screen_height)
	love.graphics.setFont(assets.fonts.RasterForgeRegular(16))

	love.mouse.setVisible(false)
	-- love.mouse.setGrabbed(true)

	level = Level(vec2(screen_width/2, screen_height/2), 480, 480, 0, true)

	effect = moonshine(moonshine.effects.crt).chain(moonshine.effects.glow)
	local cursor = Cursor(vec2(0, 0), vec2(3, 3))
	player = Player(vec2(360, 360), vec2(2, 2))
	table.insert(entities, cursor)
	table.insert(entities, player)
end

local angle = 0
function love.update(dt)
	lastShotTime = lastShotTime + dt
	if love.mouse.isDown(1) and lastShotTime >= shootCooldown then
        local newBullet = player:shoot()
        table.insert(entities, newBullet)
        lastShotTime = 0
    end

	level:update(dt)
	angle = angle + dt * 0.8

	-- Update all entities
	for i = #entities, 1, -1 do
	    local entity = entities[i]
	    if entity.isValid then
	        entity:update(dt, (entity:is(Player) or entity:is(Bullet)) and level or nil)
	    else
	    	-- Remove invalid entities
	        table.remove(entities, i)
	    end
	end

	-- Check collisions
	for i = 1, #entities - 1 do
		for j = i + 1, #entities do
			local a, b = entities[i], entities[j]
			if a:overlaps(b) then
				-- print("Collision between " .. tostring(a) .. " and " .. tostring(b))
				local msv = a:resolveCollision(b, 0.5)
			end
		end
	end
end

function love.draw()
    effect(function()
    	love.graphics.setLineWidth(2)
    	love.graphics.setColor(1, 0, 0.267, 1)
    	love.graphics.print("Ready or not, give me all that you've got!", 15, 15)
    	love.graphics.setColor(1, 1, 1, 1)
      	drawRotatedRectangle("line", screen_width/2, screen_height/2, 480 + 20, 480 + 20, angle)
      	level:draw()
		for _, entity in ipairs(entities) do
			entity:draw()
			-- entity:drawHitbox()
		end
    end)
end

function drawRotatedRectangle(mode, x, y, width, height, angle)
	-- We cannot rotate the rectangle directly, but we
	-- can move and rotate the coordinate system.
	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.rotate(angle)
	love.graphics.rectangle(mode, -width/2, -height/2, width, height) -- origin in the middle   
	love.graphics.pop()
end

local loveErrorHandler = love.errorhandler

function love.errorhandler(msg)
    if lldebugger then
        error(msg, 2)
    else
        return loveErrorHandler(msg)
    end
end