AttractMode = class()

AttractMode.titleColor = color(255, 0, 92, 255)
AttractMode.waterHeight = HEIGHT
AttractMode.help = {
    "Take the junk out of the river with your line.",
    "One-finger controls: left & right moves the angler, up & down reels the line in/out.",
    "Bumping junk that you have caught will dislodge it from your line.",
    "Don't catch the fish with your line.",
    "If you catch a fish, dislodge it from your line and it will swim away.",  
    "When all the fish have swum away, the game is over.",
    "Don't let any junk float downstream to earn a higher score multiplier.",
    "The more you catch, the more the fish will be curious about your line",
    "Lonely fish are more curious"
}

-- currently used by Fish:drawDebug, should find better way
AttractMode.caughtCount = 0
AttractMode.fishCount = 0 

function AttractMode:start()
    self.fish = PhysicalGroup()
    for i = 1, 12 do
        self.fish:add(Fish(self))
    end
    
    self.helpBanner = Banner {
        font = "PartyLetPlain",
        fontSize = 40,
        fill = self.titleColor,
        lines = self.help,
        pos = vec2(WIDTH/2, HEIGHT/4)
    }
    
    self.musicPlayer = ABCMusic(randomElement(Tunes), true)
    
    self.highscore = readHighscore()
end

function AttractMode:animate(dt)
    self.helpBanner:animate(dt)
    self.fish:animate(dt)
    self.musicPlayer:play()
    
    if self.fish:isEmpty() then
        switchMode(PlayMode())
    end
end

function AttractMode:touched(t)
    if t.state == BEGAN then
        self.fish:each(function(fish)
            fish:swimAwayFrom(t)
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
    self.helpBanner:draw()
    popStyle()
    fontSize(40)
    text("Tap to Start", self.helpBanner.pos.x, self.helpBanner.pos.y-48)
    text("Highscore: " .. self.highscore, WIDTH/2, 7*HEIGHT/16)
end

function AttractMode:drawDebug()
    self.fish:drawDebug()
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
