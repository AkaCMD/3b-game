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
Pubsub = require("lib.batteries.pubsub")
Mathx = require("lib.batteries.mathx")
require("src.entity")
require("src.cursor")
require("src.player")
require("src.bullet")
require("src.level")
require("src.world")
require("src.enemy_spawner")
require("src.enemy")
require("src.ui")
require("src.utils")
require("src.edge")

World = World()

SCREEN_WIDTH = 720
SCREEN_HEIGHT = 720

local shootCooldown = 0.1
local lastShotTime = 0
  
local level
local effect

local title = "Bravo! Border Breaker"
local default_font
PALETTE = {
	white = {1, 1, 1, 1},
	red   =	{1, 0, 0.267, 1},
	green = {0, 0.58, 0.47, 1},
}
bus = Pubsub()

-- Screen shake
local t, shakeDuration, shakeMagnitude = 0, -1, 0

-- Scene
local sceneManager
local state = {}
state.gameplay = {}
state.menu = {}
state.pause = {}
state.gameover = {}

---@type number Timer
local timer = 0.0

local function initGame()
	World:clear()

	timer = 0.0

	level = Level(vec2(SCREEN_WIDTH/2, SCREEN_HEIGHT/2), 480, 480, 0, false)

	player = Player(vec2(360, 360), vec2(1.5, 1.5))
	local cursor = Cursor(vec2(0, 0), vec2(3, 3))
	World:add_entity(cursor)
	World:add_entity(player)

	-- World:add_entity(Enemy.Builder:new()
	-- 				:withPosition(300, 300)
	-- 				:withSpeed(100)
	-- 				:withScale(1.5, 1.5)
	-- 				:build())
	-- World:add_entity(Enemy.Builder:new()
	-- 				:withPosition(200, 300)
	-- 				:withSpeed(100)
	-- 				:withScale(1.5, 1.5)
	-- 				:build())
	-- World:add_entity(Enemy.Builder:new()
	-- 				:withPosition(500, 300)
	-- 				:withSpeed(100)
	-- 				:withScale(1.5, 1.5)
	-- 				:build())

	timerUI = UI(timer, 30, PALETTE.red, SCREEN_WIDTH/2, 50, true, 0)
end

function love.load()
	love.keyboard.setTextInput(false)
	love.window.setTitle(title)
	love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)
	default_font = Assets.fonts.RasterForgeRegular(16)
	love.graphics.setFont(default_font)
	-- love.mouse.setGrabbed(true)
	effect = Moonshine(Moonshine.effects.crt).chain(Moonshine.effects.glow)

	initGame()

	sceneManager = Roomy.new()
	sceneManager:hook()
	sceneManager:enter(state.menu)

	-- Init event bus
	bus:subscribe("enemy_killed", function ()
		startShake(0.2, 0.15)
	end)
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

function love.draw()
	logger.draw()
end

-- ============ Scene: Gameplay ============
local timerUI = UI(timer, 30, PALETTE.red, SCREEN_WIDTH/2, 50, true, 0)
function state.gameplay:enter()
	love.mouse.setVisible(false)
end

local angle = 0
function state.gameplay:draw()
    effect(function()

		if t < shakeDuration then
			local dx = love.math.random(-shakeMagnitude, shakeMagnitude)
			local dy = love.math.random(-shakeMagnitude, shakeMagnitude)
			love.graphics.translate(dx, dy)
		end

    	love.graphics.setLineWidth(2)
    	-- love.graphics.setColor(1, 0, 0.267, 1)
    	-- love.graphics.print("Ready or not, give me all that you've got!", 15, 15)
    	love.graphics.setColor(PALETTE.white)

		-- Draw level bound
		if level.isRotating then
      		drawRotatedRectangle("line", SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 480 + 20, 480 + 20, angle)
		else
			drawRotatedRectangle("line", SCREEN_WIDTH/2, SCREEN_HEIGHT/2, 480 + 20, 480 + 20, 0)
		end
      	level:draw()

		-- Draw entities
		for _, entity in ipairs(World.entities) do
			entity:draw()
			entity:drawHitbox()
		end

		-- Draw UI elements
		drawHeartShapes(vec2(110, SCREEN_HEIGHT - 90))
		timerUI:draw()
    end)
end

function state.gameplay:update(dt)
	-- Check conditions
	if player.health <= 0 then
		sceneManager:enter(state.gameover)
	end

	-- Update timers
	timer = timer + dt
	if t < shakeDuration then
		t = t + dt
	end

	lastShotTime = lastShotTime + dt
	angle = angle + dt * 0.8
	-- Player shoots bullet
	if love.mouse.isDown(1) and lastShotTime >= shootCooldown then
        local newBullet = player:shoot()
		World:add_entity(newBullet)
        lastShotTime = 0
    end

	-- Update other systems
	level:update(dt)

	-- Update all entities
	World:update(dt, level)

	-- Check collisions
	World:check_collisions()

	-- Update UI elements
	timerUI.content = formatTimer(timer)
end

function state.gameplay:keypressed(key)
	if key == "escape" then
		sceneManager:push(state.pause)
	end
end
-- =====================================

-- ============ Scene: Menu ============
local title = UI(title, 32, PALETTE.red, SCREEN_WIDTH/2, SCREEN_HEIGHT/2 - 100, true, 0)
local pressKey = UI("Press Any Key To Fight", 16, PALETTE.white, SCREEN_WIDTH/2, SCREEN_HEIGHT/2 + 80, true, 0)
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
-- =====================================

-- ============ Scene: Pause ============
local pauseText = UI("PAUSE", 40, PALETTE.white, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, true, 0)
function state.pause:draw()
	pauseText:draw()
end

function state.pause:keypressed(key)
	if key == "escape" then
		sceneManager:pop()
	end
end
-- =====================================

-- ============ Scene: GameOver ============
local gameoverText = UI("GAMEOVER", 40, PALETTE.red, SCREEN_WIDTH/2, SCREEN_HEIGHT/2-150, true, 0)
local resultText = UI("You Lived For xx", 40, PALETTE.white, SCREEN_WIDTH/2, SCREEN_HEIGHT/2-50, true, 0)
local hintText = UI("R to Retry...", 40, PALETTE.white, SCREEN_WIDTH/2, SCREEN_HEIGHT/2+50, true, 0)
function state.gameover:draw()
	gameoverText:draw()
	resultText.content = "You Live for " .. formatTimer(timer)
	resultText:draw()
	hintText:draw()
end

function state.gameover:keypressed(key)
	if key == "r" then
		initGame()
		sceneManager:enter(state.gameplay)
	end
end
-- =====================================

---@param duration number
---@param magnitude number
function startShake(duration, magnitude)
	t, shakeDuration, shakeMagnitude = 0, duration or 1, magnitude or 5
end

---@param startPos vec2
function drawHeartShapes(startPos)
	local img = Assets.images.heart
	local size = img:getHeight()
	local pos = startPos
	local scale = 3
	for i = 1, player.health do
		love.graphics.draw(img, pos.x, pos.y, 0, scale, scale)
		pos = vec2(pos.x + size*scale + 10, pos.y)
	end
end

function formatTimer(timer)
    local minutes = math.floor(timer / 60)
    local seconds = math.floor(timer % 60)
    local milliseconds = math.floor((timer * 1000) % 1000 / 10)
    return string.format("%02d:%02d:%02d", minutes, seconds, milliseconds)
end