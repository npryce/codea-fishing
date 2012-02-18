GameOverMode = class()

function GameOverMode:init(playMode)
    self.playMode = playMode
end

function GameOverMode:start()
    self.inactiveTimer = 2 -- seconds
end

function GameOverMode:animate(dt)
    self.playMode:animate(dt)
    self.inactiveTimer = math.max(self.inactiveTimer - dt, 0)
end

function GameOverMode:draw()
    self.playMode:draw()
    
    noSmooth()
    rectMode(CORNER)
    fill(0, 0, 0, 80)
    rect(0, 0, WIDTH, HEIGHT)
    
    smooth()
    font("PartyLetPlain")
    textMode(CENTER)
    textWrapWidth(WIDTH)
    fill(AttractMode.titleColor)
    fontSize(132)
    sillyText("Game Over", WIDTH/2, HEIGHT/2)
    
    if self.inactiveTimer == 0 then
        fontSize(80)
        sillyText("Tap to Continue", WIDTH/2, HEIGHT/4)
    end
end

function GameOverMode:touched(t)
    if self.inactiveTimer == 0 then
        switchMode(AttractMode())
    end
end

function GameOverMode:collide(c)
end

function GameOverMode:stop()
    self.playMode:destroy()
end
