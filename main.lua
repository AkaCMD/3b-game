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
local GameplayEffects = require("src.gameplay_effects")

World = World()

SCREEN_WIDTH = 720
SCREEN_HEIGHT = 720

local Timers = {}
local level
local effect
local powerupUI
local waveManager

local title = "Bravo! Border Breaker"
local default_font
PALETTE = {
	white = {1, 1, 1, 1},
	red   =	{1, 0, 0.267, 1},
	green = {0, 0.58, 0.47, 1},
}
bus = World

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
	Enemy:flush_pool()
	Bullet:flush_pool()

	timer = 0.0
    powerupUI = nil
    waveManager = nil

	level = Level(vec2(SCREEN_WIDTH/2, SCREEN_HEIGHT/2), 480, 480, 0, false)

	player = Player(vec2(360, 360), vec2(1.5, 1.5))
	local cursor = Cursor(vec2(0, 0), vec2(3, 3))
	World:add_entity(cursor)
	World:add_entity(player)
end

function love.load()
	love.keyboard.setTextInput(false)
	love.window.setTitle(title)
	love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)
	default_font = Assets.fonts.RasterForgeRegular(16)
	love.graphics.setFont(default_font)
	BloodBatch = love.graphics.newSpriteBatch(Assets.images.enemy_blood)
	-- love.mouse.setGrabbed(true)
	effect = Moonshine(Moonshine.effects.crt)
			.chain(Moonshine.effects.glow)
			.chain(Moonshine.effects.chromasep)
	effect.parameters = {
		chromasep = {angle = math.pi/6, radius = 8},
	}
	effect.disable("chromasep")

	math.randomseed(os.time())
	initGame()

	sceneManager = Roomy.new()
	sceneManager:hook()
	sceneManager:enter(state.menu)

	-- Init event bus
	bus:subscribe("enemy_killed", function ()
		startShake(0.2, 0.15)
	end)
	bus:subscribe("player_take_damage", function ()
		effect.enable("chromasep")
		local vfxTimer = Batteries.timer(
			0.3,
			nil,
			function ()
				effect.disable("chromasep")
			end
		)
		table.insert(Timers, vfxTimer)
	end)

	-- Load Sound Assets
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

function love.update(dt)
	Flux.update(dt)
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
local timerUI = Text(timer, 30, PALETTE.red, SCREEN_WIDTH/2, 50, true, 0)
local waveStatusUI = Text("", 18, PALETTE.green, SCREEN_WIDTH/2, 88, true, 0)
local upgradeHintUI = Text("", 14, PALETTE.white, SCREEN_WIDTH/2, 114, true, 0)

local function is_upgrade_pause_active()
	return powerupUI and powerupUI:isActive()
end

function state.gameplay:enter()
	love.mouse.setVisible(false)
	powerupUI = PowerupScreenUI(player, function()
        if waveManager then
            waveManager:complete_upgrade_selection()
        end
    end)
    waveManager = WaveManager(World, {
        initial_delay = 1.0,
        upgrade_every = 3,
        on_upgrade_ready = function()
            return powerupUI and powerupUI:offer_random_upgrades() or false
        end,
    })
end

local angle = 0
function state.gameplay:draw()
    effect(function()

		if GameplayEffects.should_draw_shake(t, shakeDuration, is_upgrade_pause_active()) then
			local dx = love.math.random(-shakeMagnitude, shakeMagnitude)
			local dy = love.math.random(-shakeMagnitude, shakeMagnitude)
			love.graphics.translate(dx, dy)
		end

    	love.graphics.setLineWidth(2)
    	love.graphics.setColor(PALETTE.white)

		-- Draw level bound
      	level:draw()

		love.graphics.draw(BloodBatch)
		-- Draw entities
		for _, entity in ipairs(World.entities) do
			entity:draw()
			entity:drawHitbox()
		end

		-- Draw UI elements
		drawHeartShapes(vec2(110, SCREEN_HEIGHT - 90))
		timerUI:draw()
        waveStatusUI:draw()
        upgradeHintUI:draw()

    end)
	if powerupUI then
		powerupUI:draw()
	end
end

function state.gameplay:update(dt)
	-- Update timers
	for i = #Timers, 1, -1 do
		Timers[i]:update(dt)
	end

	if t < shakeDuration then
		t = GameplayEffects.advance_shake_time(t, shakeDuration, dt)
	end

	if is_upgrade_pause_active() then
		if powerupUI then
			powerupUI:update(dt)
		end
		return
	end

	-- Check conditions
	if player.health <= 0 then
		sceneManager:enter(state.gameover)
	end

	timer = timer + dt

	angle = angle + dt * 0.8

	-- Update other systems
	level:update(dt)

	-- Update all entities
	World:update(dt, level)

	-- Check collisions
	World:check_collisions()

    if waveManager then
        waveManager:update(dt)
        waveStatusUI.content = waveManager:get_wave_text()
        upgradeHintUI.content = waveManager:get_upgrade_progress_text()
    end

	-- Update UI elements
	timerUI.content = formatTimer(timer)

	if powerupUI then
		powerupUI:update(dt)
	end
end

function state.gameplay:mousereleased(x, y, button)
	if powerupUI and powerupUI:isActive() then
		powerupUI:mousereleased(x, y, button)
		return
	end
end

function state.gameplay:keypressed(key)
	if key == "escape" then
		sceneManager:push(state.pause)
	end
	player:keypressed(key)

	--@test
	if key == "1" then
		level:clearEdges()
        level:randomizeEdges()
	end
	if key == "2" then
		level:shrinkLevel()
	end

	if key == "u" and powerupUI then
        local shown = powerupUI:offer_random_upgrades()
        if waveManager then
            waveManager.awaitingUpgradeSelection = shown == true
        end
	end
end
-- =====================================

-- ============ Scene: Menu ============
local title = Text(title, 32, PALETTE.red, SCREEN_WIDTH/2, SCREEN_HEIGHT/2 - 100, true, 0)
local pressKey = Text("Press Any Key To Fight", 16, PALETTE.white, SCREEN_WIDTH/2, SCREEN_HEIGHT/2 + 80, true, 0)
local myButton = Button(100, 100, 200, 50, "Click me!", function(btn)
	print("Button '" .. btn.text .. "' clicked! Count: " .. (btn.clickCount or 0))
end)
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
	myButton:draw()
end

function state.menu:update(dt)
	myButton:update(dt)
end

function love.mousereleased(x, y, button)
    if powerupUI and powerupUI:isActive() then
        powerupUI:mousereleased(x, y, button)
        return
    end
	local allButtons = { myButton }
	Button.checkClicks(allButtons)
end

function state.menu:keypressed(key)
	if key ~= nil then
		sceneManager:enter(state.gameplay)
	end
end
-- =====================================

-- ============ Scene: Pause ============
local pauseText = Text("PAUSE", 40, PALETTE.white, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, true, 0)
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
local gameoverText = Text("GAMEOVER", 40, PALETTE.red, SCREEN_WIDTH/2, SCREEN_HEIGHT/2-150, true, 0)
local resultText = Text("You Lived For xx", 40, PALETTE.white, SCREEN_WIDTH/2, SCREEN_HEIGHT/2-50, true, 0)
local hintText = Text("R to Retry...", 40, PALETTE.white, SCREEN_WIDTH/2, SCREEN_HEIGHT/2+50, true, 0)
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
