PlayMode = class()

PlayMode.waterHeight = HEIGHT-160
PlayMode.scoreAlpha = 202
PlayMode.highscoreColor = color(255, 242, 0, PlayMode.scoreAlpha)

function PlayMode:start()
    self.caughtCount = 0
    self.score = 0
    self.scoreMultiplier = 1
    self.highscore = readHighscore()
    self.fishCount = 3
    
    self.edge = physics.body(EDGE, 
            vec2(0,self.waterHeight), vec2(WIDTH, self.waterHeight))
    self.edge.type = STATIC
    self.edge.categories = {CATEGORY_EDGE}
    
    self.player = Angler(vec2(WIDTH/2, HEIGHT-80))
    self.stuff = PhysicalGroup()
    self.effects = Group()
    
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

function PlayMode:createBubble(pos, vel)
    function bubbleIsAlive(b)
        return Particle.isAlive(b) and b.pos.y < self.waterHeight
    end
    
    self.effects:add(Particle {
        pos = pos,
        vel = vel or vec2(0,0),
        acc = vec2(0, 100),
        drag = 0.1,
        isAlive = bubbleIsAlive,
        initialColor = color(255, 255, 255, 255),
        finalColor = color(255, 255, 255, 0),
        lifespan = 10
    })
end

function PlayMode:hookPosition()
    return self.player:hookPosition()
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
        
        self:createBubble(c.position)
        sound(DATA, "ZgJAHgAzVztIAABPAAAAABzxzD4AAAAAXQA5Vh1AK0I8OmZQ")
    end
end

function PlayMode:animate(dt)
    self.player:animate(dt)
    self.stuff:animate(dt)
    self.effects:animate(dt)
end

function PlayMode:draw()
    background(131, 172, 224, 255)
    
    drawDock()
    self.stuff:draw()
    self.player:draw()
    self.effects:draw()
    
    if DEBUG > 0 then
        self:drawDebug()
    end
    
    self:drawScore()
end

function PlayMode:totalScoreMultiplier()
    return self.scoreMultiplier * self.fishCount
end

function PlayMode:drawScore()
    textMode(CORNER)
    font("DB LCD Temp")
    local alpha = 202
    
    if self.score > self.highscore then
        fill(self.highscoreColor)
    else
        fill(255, 255, 255, self.scoreAlpha)
    end
    
    local scoreText = self.score
    
    fontSize(64)
    local sw, sh = textSize(scoreText)
    text(scoreText, WIDTH-(sw+16), HEIGHT-(sh+16))
        
    fontSize(24)
    local multiplierText = "x"..self:totalScoreMultiplier()
    local mw, mh = textSize(multiplierText)
    text(multiplierText, WIDTH-(mw+16), HEIGHT-(sh+16+mh))
end

function PlayMode:drawDebug()
    self.player:drawDebug()
    self.stuff:drawDebug()
    self.controller:draw()
    self:drawEdge(self.edge)
end

function PlayMode:drawEdge(body)
    stroke(0, 255, 0, 255)
    strokeWidth(5.0)
    local points = body.points
    for j = 1,#points-1 do
        a = points[j]
        b = points[j+1]
        line(a.x, a.y, b.x, b.y)
    end
end

function PlayMode:flotsamLanded(flotsam)
    self.player:maybeRelease(flotsam)
    
    local hadHighscore = self.score > self.highscore
    
    self.caughtCount = self.caughtCount + 1
    self.score = self.score + self:totalScoreMultiplier()
    self.scoreMultiplier = self.scoreMultiplier + 1
    
    local hasHighscore = self.score > self.highscore
    
    fontSize(64)
    local sw, sh = textSize(self.score)
    local sx = WIDTH - 16 - sw
    local sy = HEIGHT - 16 - sh
    local mid = vec2(sx+sw/2, sy+sh/2)
    
    self.effects:add(
        SpinningSprite(flotsam.image, flotsam.body.position, mid))   
    
    if hasHighscore and not hadHighscore then
        local function createHighscoreSpark(x, y)
            local p = vec2(x,y)
            self.effects:add(Particle {
                pos = p,
                vel = (p-mid):normalize() * math.random(10,40),
                acc = vec2(0, -10),
                lifespan = 1,
                initialColor = alpha(self.highscoreColor, 255),
                finalColor = alpha(self.highscoreColor, 0)
            })
        end
        
        for px = 0, sw, 8 do
            createHighscoreSpark(sx+px,sy)
            createHighscoreSpark(sx+px,sy+sh)
        end
        for py = 0, sh, 8 do
            createHighscoreSpark(sx,sy+py)
            createHighscoreSpark(sx+sw,sy+py)
        end
        
        sound(DATA, "ZgFAPwA/PxM4ailttTSCvUPHjT7EgQS/SABYR0BAPj5ATR5m")
    else
        sound(DATA, "ZgBAMgBAPhw/P3xBGODOve1ExD7wpXW9SwBQVBFCPT5CPHFd")
    end
    
    
    flotsam:launch()
end

function PlayMode:flotsamEscaped(flotsam, p)
    if p.x < 0 then
        self.scoreMultiplier = 1
    end
    
    flotsam:launch()
end

function PlayMode:fishEscaped(fish)
    self.fishCount = self.fishCount - 1
    self.scoreMultiplier = 1
    
    if self.fishCount == 0 then
        switchMode(GameOverMode(self))
    end
end

function PlayMode:stop()
    self.player:steer(0)
    self.player:reel(0)
    
    if self.score > self.highscore then
        saveHighscore(self.score)
    end
end

function PlayMode:destroy()
    self.player:destroy()
    self.stuff:destroy()
end