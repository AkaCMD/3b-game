---@param _app table
return function(_app)
    local scene = {}
    local pauseText = Text("PAUSE", 40, PALETTE.white, SCREEN_WIDTH/2, SCREEN_HEIGHT/2, true, 0)

    function scene:draw()
        pauseText:draw()
    end

    ---@param key string
    function scene:keypressed(key)
        if key == "escape" then
            _app.sceneManager:pop()
        end
    end

    return scene
end
