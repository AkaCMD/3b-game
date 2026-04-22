return function(app)
    local scene = {}
    local gameoverText = Text("GAMEOVER", 40, PALETTE.red, SCREEN_WIDTH/2, SCREEN_HEIGHT/2-150, true, 0)
    local resultText = Text("You Lived For xx", 40, PALETTE.white, SCREEN_WIDTH/2, SCREEN_HEIGHT/2-50, true, 0)
    local hintText = Text("R to Retry...", 40, PALETTE.white, SCREEN_WIDTH/2, SCREEN_HEIGHT/2+50, true, 0)

    function scene:draw()
        gameoverText:draw()
        resultText.content = "You Live for " .. app.formatTimer(app.timer)
        resultText:draw()
        hintText:draw()
    end

    function scene:keypressed(key)
        if key == "r" then
            app.initGame()
            app.sceneManager:enter(app.state.gameplay)
        end
    end

    return scene
end
