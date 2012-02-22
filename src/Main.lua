-- Main

-- TODO:
-- flotsam &/or fish move faster as score gets higher
-- bonus flotsam creates a new fish (or other benefit) when landed
-- water ripple effect
-- effect when player gets the highscore
-- show on game over screen is player got the highscore
-- emit bubbles (particles) when actors collide
-- sfx
-- custom spritepack


DEBUG=0
iparameter("DEBUG", 0, 1)

supportedOrientations(LANDSCAPE_ANY)
displayMode(FULLSCREEN)

function setup()
    --saveHighscore(0) -- uncomment to clear highscore for testing
    
    Fish.setup()
    Flotsam.setup()
    
    mode = AttractMode()
    mode:start()
end

function switchMode(newMode)
    mode:stop()
    mode = newMode
    mode:start()
end

function draw()
    mode:animate(DeltaTime)
    mode:draw()
    if DEBUG > 0 then
        mode:drawDebug()
    end
end

function touched(t)
    if t.state == BEGAN and t.tapCount == 3 and t.x < 64 and t.y >= (HEIGHT-64) then
        DEBUG = 1 - DEBUG
    else
        mode:touched(t)
    end
end

function collide(c)
    if c.state == BEGAN then
        mode:collide(c)
    end
end

function readHighscore()
    return readLocalData("highscore", 1)
end

function saveHighscore(newHighscore)
    saveLocalData("highscore", newHighscore)
end

