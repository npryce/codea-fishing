AttractMode = class()

function AttractMode:start()
    self.fish = Group()
    for i = 1, 12 do
        self.fish:add(Fish())
    end
end

function AttractMode:animate(dt)
    self.fish:animate(dt)
    if self.fish:isEmpty() then
        switchMode(PlayMode())
    end
end

function AttractMode:touched(t)
    if t.state == BEGAN then
        self.fish:each(function(fish)
            fish:swimAway(t)
        end)
    end
end

function AttractMode:draw()
    background(131, 172, 224, 255)
    self.fish:draw()
    
    font("PartyLetPlain")
    textMode(CENTER)
    textWrapWidth(WIDTH)
    fill(255, 0, 92, 255)
    fontSize(132)
    sillyText("Help the Fish", WIDTH/2, 2*HEIGHT/3)
    
    fontSize(80)
    sillyText("Tap to Start", WIDTH/2, HEIGHT/4)
end

function sillyText(str, x, y)
    pushStyle()
    fontSize(fontSize()+2)
    fill(0, 0, 0, 31)
    text(str, x, y-2)
    popStyle()
    text(str, x, y)
end

function AttractMode:collide(c)
    -- don't care
end

function AttractMode:stop()
end
