---@param app table
return function(app)
    local scene = {}
    local titleText = Text(app.title, 32, PALETTE.red, SCREEN_WIDTH/2, SCREEN_HEIGHT/2 - 100, true, 0)
    local pressKeyText = Text("Press Any Key To Fight", 16, PALETTE.white, SCREEN_WIDTH/2, SCREEN_HEIGHT/2 + 80, true, 0)

    function scene:enter()
        local function titleWobbling()
            Flux.to(titleText, 2, {rot = -0.1})
                :after(titleText, 2, {rot = 0.1})
                :oncomplete(titleWobbling)
        end
        titleWobbling()

        local function pressKeyBlink()
            Flux.to(pressKeyText, 1, { a = 0 })
                :after(pressKeyText, 1, { a = 1 })
                :oncomplete(pressKeyBlink)
        end
        pressKeyBlink()
    end

    function scene:draw()
        titleText:draw()
        pressKeyText:draw()
    end

    ---@param _dt number
    function scene:update(_dt)
    end

    ---@param key string
    function scene:keypressed(key)
        if key ~= nil then
            app.sceneManager:enter(app.state.gameplay)
        end
    end

    return scene
end
