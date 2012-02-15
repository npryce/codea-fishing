-- Main

-- TODO
-- game over when no more fish
-- hook points at center of hooked thing
-- when flotsam landed, get score multiplier, which is lost when some flotsam floats offscreen
-- bonus flotsam creates a new fish (or other effects)
-- water ripple effect
-- sfx
-- save highscore
-- wear crown if have hiscore
-- custom spritepack


DEBUG=0

supportedOrientations(LANDSCAPE_ANY)

hiscore = 10

function setup()
    iparameter("DEBUG", 0, 1)
    --displayMode(FULLSCREEN_NO_BUTTONS)
    
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





