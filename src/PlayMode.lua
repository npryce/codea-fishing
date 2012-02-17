PlayMode = class()

PlayMode.waterHeight = WATER_HEIGHT

function PlayMode:start()
    self.caughtCount = 0
    self.score = 0
    self.scoreMultiplier = 1
    
    self.hiscore = readHighscore()
    self.fishCount = 3
    
    self.edge = physics.body(EDGE, 
            vec2(0,WATER_HEIGHT), vec2(WIDTH, WATER_HEIGHT))
    self.edge.type = STATIC
    self.edge.categories = {CATEGORY_EDGE}
    
    self.player = Angler(vec2(WIDTH/2, HEIGHT-80))
    self.stuff = Group()
    self.bodyOwners = {}
    
    for i = 1, self.fishCount do
        self.stuff:add(Fish(self))
    end
    
    for i = 1, 10 do
        self.stuff:add(Flotsam(self))
    end
    
    self.controller = All {
        VirtualSlider {
            orientation = vec2(1,0),
            moved = function(amount) self.player:steer(amount) end,
            released = function() self.player:steer(0) end
        },
        VirtualSlider {
            orientation = vec2(0, -1),
            moved = function (amount) self.player:reel(amount) end,
            released = function(y) self.player:reel(0) end
        }
    }
end

function PlayMode:touched(t)
    self.controller:touched(t)
end

function PlayMode:collide(c)
    local actorA = self.stuff:ownerOf(c.bodyA)
    local actorB = self.stuff:ownerOf(c.bodyB)
    
    if c.bodyA == self.player.hook then
        self.player:catch(actorB)
    elseif c.bodyB == self.player.hook then
        self.player:catch(actorA)
    elseif actorA and actorB then
        self.player:maybeRelease(actorA)
        self.player:maybeRelease(actorB)
    end
end

function PlayMode:animate(dt)
    self.player:animate(dt)
    self.stuff:animate(dt)
end

function PlayMode:draw()
    background(131, 172, 224, 255)
    
    drawDock()
    self.stuff:draw()
    self.player:draw()
    
    if DEBUG > 0 then
        stroke(255, 0, 0, 255)
        self.controller:draw()
        self:drawEdge(self.edge)
    end
    
    self:drawScore()
end

function PlayMode:drawScore()
    textMode(CORNER)
    font("DB LCD Temp")
    fill(255, 255, 255, 202)
    
    fontSize(64)
    sw, sh = textSize(self.score)
    text(self.score, WIDTH-(sw+16), HEIGHT-(sh+16))
    
    fontSize(24)
    local multiplierText = "x"..self.scoreMultiplier
    mw, mh = textSize(multiplierText)
    text(multiplierText, WIDTH-(mw+16), HEIGHT-(sh+16+mh))
end

function PlayMode:drawEdge(body)
    strokeWidth(5.0)
    local points = body.points
    for j = 1,#points-1 do
        a = points[j]
        b = points[j+1]
        line(a.x, a.y, b.x, b.y)
    end
end

function PlayMode:flotsamLanded(flotsam)
    self.caughtCount = self.caughtCount + 1
    self.score = self.score + self.scoreMultiplier
    self.scoreMultiplier = self.scoreMultiplier + 1
end

function PlayMode:flotsamEscaped(flotsam)
    self.scoreMultiplier = 1
end

function PlayMode:fishEscaped(fish)
    self.fishCount = self.fishCount - 1
    self.scoreMultiplier = 1
    
    if self.fishCount == 0 then
        switchMode(GameOverMode(self))
    end
end

function PlayMode:stop()
    -- not required
end

function PlayMode:destroy()
    self.player:destroy()
    self.stuff:each(function (x) x:destroy() end)
end