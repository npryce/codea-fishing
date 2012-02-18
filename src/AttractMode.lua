AttractMode = class()

AttractMode.titleColor = color(255, 0, 92, 255)
AttractMode.waterHeight = HEIGHT
AttractMode.help = {
    "Take the junk out of the river with your line.",
    "Bumping junk that you have caught will dislodge it from your line.",
    "Don't catch the fish with your line.",
    "If you catch a fish, dislodge it from your line and it will swim away.",  
    "When all the fish have swum away, the game is over.", 
    "1-Finger Controls: left/right moves the angler, up/down reels the line in/out",
    "Tap to start",
}

function AttractMode:start()
    self.fish = PhysicalGroup()
    for i = 1, 12 do
        self.fish:add(Fish(self))
    end
    
    self.help = Banner {
        font = "PartyLetPlain",
        fontSize = 40,
        fill = self.titleColor,
        lines = self.help,
        pos = vec2(WIDTH/2, HEIGHT/4)
    }
    
    self.highscore = readHighscore()
end

function AttractMode:animate(dt)
    self.help:animate(dt)
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
    fill(self.titleColor)
    fontSize(132)
    sillyText("Help the Fish", WIDTH/2, 11*HEIGHT/16)
    
    pushStyle()
    self.help:draw()
    popStyle()
    
    fontSize(40)
    sillyText("Highscore: " .. self.highscore, WIDTH/2, 7*HEIGHT/16)
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

function AttractMode:fishEscaped(fish)
    -- don't care
end

function AttractMode:stop()
end
