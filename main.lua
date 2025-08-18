io.stdout:setvbuf("no")
if arg[2] == "debug" then
    require("lldebugger").start()
end

love.graphics.setDefaultFilter("nearest", "nearest")

Batteries = require("lib.batteries"):export()
Assets = require("lib.cargo.cargo").init("assets")
Moonshine = require("lib.moonshine")
Roomy = require("lib.roomy")
Flux = require("lib.flux.flux")
require("src.entity")
require("src.cursor")
require("src.player")
require("src.bullet")
require("src.level")
require("src.world")
require("src.enemy_spawner")
require("src.enemy")
require("src.ui")

local world = World()

SCREEN_WIDTH = 720
SCREEN_HEIGHT = 720

local shootCooldown = 0.1
local lastShotTime = 0
  
local level
local effect

local enemySpawner

local title = "Bravo! Border Breaker"
local default_font
THEME_COLOR = {
	
}
-- Scene
local sceneManager
local state = {}
state.gameplay = {}
state.menu = {}
state.pause = {}

function love.load()
	love.window.setTitle(title)
	love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)
	default_font = Assets.fonts.RasterForgeRegular(16)
	love.graphics.setFont(default_font)

	-- love.mouse.setGrabbed(true)

	level = Level(vec2(SCREEN_WIDTH/2, SCREEN_HEIGHT/2), 480, 480, 0, false)

	effect = Moonshine(Moonshine.effects.crt).chain(Moonshine.effects.glow)
	local cursor = Cursor(vec2(0, 0), vec2(3, 3))
	player = Player(vec2(360, 360), vec2(1.5, 1.5))
	-- For test
	world:add_entity(Enemy(vec2(300, 300), 0, vec2(1.5, 1.5), 100))
	world:add_entity(Enemy(vec2(200, 300), 0, vec2(1.5, 1.5), 100))
	world:add_entity(Enemy(vec2(500, 300), 0, vec2(1.5, 1.5), 100))
	
	world:add_entity(cursor)
	world:add_entity(player)
	enemySpawner = EnemySpawner()
	sceneManager = Roomy.new()
	sceneManager:hook()
	sceneManager:enter(state.menu)
end

function love.update(dt)
	Flux.update(dt)
end

local function drawRotatedRectangle(mode, x, y, width, height, angle)
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

-- Scene: gameplay
function state.gameplay:enter()
	love.mouse.setVisible(false)
end

local angle = 0
function state.gameplay:draw()
    effect(function()
    	love.graphics.setLineWidth(2)
    	-- love.graphics.setColor(1, 0, 0.267, 1)
    	-- love.graphics.print("Ready or not, give me all that you've got!", 15, 15)
    	love.graphics.setColor(1, 1, 1, 1)
		if level.isRotating then
      		drawRotatedRectangle("line", SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 480 + 20, 480 + 20, angle)
		else
			drawRotatedRectangle("line", SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 480 + 20, 480 + 20, 0)
		end
      	level:draw()
		for _, entity in ipairs(world.entities) do
			entity:draw()
			entity:drawHitbox()
		end
    end)
end

function state.gameplay:update(dt)
	lastShotTime = lastShotTime + dt
	if love.mouse.isDown(1) and lastShotTime >= shootCooldown then
        local newBullet = player:shoot()
		world:add_entity(newBullet)
        lastShotTime = 0
    end

	level:update(dt)
	enemySpawner:update(dt)
	angle = angle + dt * 0.8

	-- Update all entities
	world:update(dt, level)

	-- Check collisions
	world:check_collisions()
end

function state.gameplay:keypressed(key)
	if key == "escape" then
		sceneManager:push(state.pause)
	end
end

-- Scene: menu
local title = UI(title, 32, {1, 0, 0.267, 1}, SCREEN_WIDTH/2, SCREEN_HEIGHT/2 - 100, true, 0)
local pressKey = UI("Press Any Key To Fight", 16, {1, 1, 1, 1}, SCREEN_WIDTH/2, SCREEN_HEIGHT/2 + 80, true, 0)
function state.menu:enter()
	local function titleWobbling()
		Flux.to(title, 2, {rot = -0.1})
			:after(title, 2, {rot = 0.1})
			:oncomplete(titleWobbling)
	end
	titleWobbling()
	local function pressKeyBlink()
        Flux.to(pressKey, 1, { a = 0 })
            :after(pressKey, 1, { a = 1 })
            :oncomplete(pressKeyBlink)
    end
    pressKeyBlink()
end

function state.menu:draw()
	title:draw()
	pressKey:draw()
end

function state.menu:keypressed(key)
	if key ~= nil then
		sceneManager:enter(state.gameplay)
	end
end

-- Scene: pause
local pauseText = UI("PAUSE", 40, {1, 1, 1, 1}, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, true, 0)
function state.pause:draw()
	pauseText:draw()
end

function state.pause:keypressed(key)
	if key == "escape" then
		sceneManager:pop()
	end
end