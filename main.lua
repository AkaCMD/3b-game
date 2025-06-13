io.stdout:setvbuf("no")
love.graphics.setDefaultFilter("nearest", "nearest")

require("lib.batteries"):export()
assets = require("lib.cargo.cargo").init("assets")
moonshine = require("lib.moonshine")
require("src.entity")
require("src.cursor")
require("src.player")
require("src.bullet")
require("src.level")

local entities = {}

function love.load()
	screen_width = 720
	screen_height = 720

	love.window.setTitle("Bravo! Border Breaker")
	love.window.setMode(screen_width, screen_height)

	love.mouse.setVisible(false)
	-- love.mouse.setGrabbed(true)

	level = Level(vec2(screen_width/2, screen_height/2), 480, 480, 0, true)

	effect = moonshine(moonshine.effects.crt).chain(moonshine.effects.glow)
	cursor = Cursor(vec2(0, 0), vec2(3, 3))
	player = Player(vec2(360, 360), vec2(2, 2))
	table.insert(entities, cursor)
	table.insert(entities, player)
end

local angle = 0
function love.update(dt)
	level:update(dt)
	angle = angle + dt * 0.8

	-- Update all entities
	for _, entity in ipairs(entities) do
		entity:update(dt, entity:is(Player) and level or nil)
	end

	-- Check collisions
	for i = 1, #entities - 1 do
		for j = i + 1, #entities do
			local a, b = entities[i], entities[j]
			if a:overlaps(b) then
				print("Collision between " .. tostring(a) .. " and " .. tostring(b))
				local msv = a:resolveCollision(b, 0.5)
				if msv then
					print("Resolved with MSV: " .. tostring(msv))
				end
			end
		end
	end
end

function love.draw()
    effect(function()
      	drawRotatedRectangle("line", screen_width/2, screen_height/2, 480 + 20, 480 + 20, angle)
      	level:draw()
		for _, entity in ipairs(entities) do
			entity:draw()
			entity:drawHitbox()
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