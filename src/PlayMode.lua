PlayMode = class()

function PlayMode:start()
    self.score = 0
    
    self.edge = physics.body(EDGE, 
            vec2(0,WATER_HEIGHT), vec2(WIDTH, WATER_HEIGHT))
    self.edge.type = STATIC
    self.edge.categories = {CATEGORY_EDGE}
    
    self.player = Angler(vec2(WIDTH/2, HEIGHT-80))
    self.stuff = Group()
    
    for i = 1, 3 do
        self.stuff:add(Fish())
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
    self.player:animate(DeltaTime)
    self.stuff:animate(DeltaTime)
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
    fontSize(64)
    fill(255, 255, 255, 202)
    
    w, h = textSize(self.score)
    text(self.score, WIDTH-(w+16), HEIGHT-(h+16))
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

function PlayMode:flotsamCaptured()
    self.score = self.score + 1
end

