-- Main

-- TODO
-- why do flotsam disappear?
-- angler wears crown when have hiscore
-- flotsam moves faster as score gets higher
-- more flotsam created as score increases
-- bonus flotsam creates a new fish (or other effects) when landed
-- water ripple effect
-- sfx
-- custom spritepack


DEBUG=0
iparameter("DEBUG", 0, 1)

supportedOrientations(LANDSCAPE_ANY)
displayMode(FULLSCREEN)

function setup()
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
end

function touched(t)
    mode:touched(t)
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

