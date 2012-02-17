-- Main

-- TODO
-- 
-- hook points at center of hooked thing
-- hiscore, show hiscore on attract screen, save hiscore
-- angler wears crown when have hiscore
-- flotsam moves faster as score gets higher
-- more flotsam created as score increases
-- bonus flotsam creates a new fish (or other effects) when landed
-- water ripple effect
-- sfx
-- custom spritepack


DEBUG=0

supportedOrientations(LANDSCAPE_ANY)

hiscore = 10

function setup()
    iparameter("DEBUG", 0, 1)
    displayMode(FULLSCREEN)
    
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
    return readLocalData("highscore", 10)
end

function saveHighscore(newHighscore)
    saveLocalData("highscore", newHighscore)
end

