io.stdout:setvbuf("no")
-- Press F5 in VSCode to debug!!!
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
require("src.text")
require("src.utils")
require("src.edge")
require("src.button")
require("src.power_up_ui")
require("src.wave_manager")
local createGameplayScene = require("src.scenes.gameplay_scene")
local createMenuScene = require("src.scenes.menu_scene")
local createPauseScene = require("src.scenes.pause_scene")
local createGameoverScene = require("src.scenes.gameover_scene")

World = World()

SCREEN_WIDTH = 720
SCREEN_HEIGHT = 720

local windowTitle = "Bravo! Border Breaker"
local default_font

PALETTE = {
	white = {1, 1, 1, 1},
	red   =	{1, 0, 0.267, 1},
	green = {0, 0.58, 0.47, 1},
}
bus = World

local app = {
    title = windowTitle,
    timers = {},
    level = nil,
    effect = nil,
    powerupUI = nil,
    waveManager = nil,
    player = nil,
    sceneManager = nil,
    timer = 0.0,
    shake = {
        t = 0,
        duration = -1,
        magnitude = 0,
    },
    state = {},
}

local function initGame()
	World:clear()
	Enemy:flush_pool()
	Bullet:flush_pool()

	app.timer = 0.0
    app.powerupUI = nil
    app.waveManager = nil

	app.level = Level(vec2(SCREEN_WIDTH/2, SCREEN_HEIGHT/2), 480, 480, 0, false)

	player = Player(vec2(360, 360), vec2(1.5, 1.5))
    app.player = player
	local cursor = Cursor(vec2(0, 0), vec2(3, 3))
	World:add_entity(cursor)
	World:add_entity(player)
end

---@param duration number
---@param magnitude number
local function startShake(duration, magnitude)
	app.shake.t = 0
    app.shake.duration = duration or 1
    app.shake.magnitude = magnitude or 5
end

---@param startPos vec2
local function drawHeartShapes(startPos)
	local img = Assets.images.heart
	local size = img:getHeight()
	local pos = startPos
	local scale = 3
	for i = 1, app.player.health do
		love.graphics.draw(img, pos.x, pos.y, 0, scale, scale)
		pos = vec2(pos.x + size*scale + 10, pos.y)
	end
end

---@param timer number
---@return string
local function formatTimer(timer)
    local minutes = math.floor(timer / 60)
    local seconds = math.floor(timer % 60)
    local milliseconds = math.floor((timer * 1000) % 1000 / 10)
    return string.format("%02d:%02d:%02d", minutes, seconds, milliseconds)
end

app.initGame = initGame
app.startShake = startShake
app.drawHeartShapes = drawHeartShapes
app.formatTimer = formatTimer

function love.load()
	love.keyboard.setTextInput(false)
	love.window.setTitle(windowTitle)
	love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)
	default_font = Assets.fonts.RasterForgeRegular(16)
	love.graphics.setFont(default_font)
	BloodBatch = love.graphics.newSpriteBatch(Assets.images.enemy_blood)
	-- love.mouse.setGrabbed(true)
	app.effect = Moonshine(Moonshine.effects.crt)
			.chain(Moonshine.effects.glow)
			.chain(Moonshine.effects.chromasep)
	app.effect.parameters = {
		chromasep = {angle = math.pi/6, radius = 8},
	}
	app.effect.disable("chromasep")

	math.randomseed(os.time())
	initGame()

    app.state.gameplay = createGameplayScene(app)
    app.state.menu = createMenuScene(app)
    app.state.pause = createPauseScene(app)
    app.state.gameover = createGameoverScene(app)

	app.sceneManager = Roomy.new()
	app.sceneManager:hook()
	app.sceneManager:enter(app.state.menu)

	bus:subscribe("enemy_killed", function ()
		startShake(0.2, 0.15)
	end)
	bus:subscribe("player_take_damage", function ()
		app.effect.enable("chromasep")
		local vfxTimer = Batteries.timer(
			0.3,
			nil,
			function ()
				app.effect.disable("chromasep")
			end
		)
		table.insert(app.timers, vfxTimer)
	end)

	Sfx_big_explosion = Assets.sfx.big_explosion
	Sfx_explosion = Assets.sfx.explosion
	Sfx_explosion:setVolume(0.2)
	Sfx_hurt = Assets.sfx.hurt
	Sfx_hurt:setVolume(1.5)
	Sfx_pickup = Assets.sfx.pickup
	Sfx_pickup:setVolume(0.2)
	Sfx_portal = Assets.sfx.portal
	Sfx_portal:setVolume(0.2)
	Sfx_power_up = Assets.sfx.power_up
	Sfx_power_up:setVolume(0.3)
	Sfx_small_hit = Assets.sfx.small_hit
	Sfx_small_hit:setVolume(0.2)
end

---@param dt number
function love.update(dt)
	Flux.update(dt)
end

local loveErrorHandler = love.errorhandler

---@param msg string
---@return function|string
function love.errorhandler(msg)
    if lldebugger then
        error(msg, 2)
    else
        return loveErrorHandler(msg)
    end
end

function love.draw()
end

---@param x number
---@param y number
---@param button integer
function love.mousereleased(x, y, button)
    if app.powerupUI and app.powerupUI:isActive() then
        app.powerupUI:mousereleased(x, y, button)
        return
    end
end
