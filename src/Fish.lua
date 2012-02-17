Fish = class()
Fish.radius = 20
Fish.spacing = 2*Fish.radius
Fish.startX = {-Fish.spacing, WIDTH+Fish.spacing}
Fish.minSpeed = 25
Fish.maxSpeed = 100
Fish.spriteYOffset = -8 -- to compensate for emoji font
Fish.swimmingMask = {CATEGORY_LINE, CATEGORY_FLOATING}
Fish.escapingMask = {CATEGORY_FLOATING}

Fish.swimmingState = 1
Fish.hookedState = 2
Fish.escapedState = 3

function Fish.setup()
    Fish.images = map(emojiToImage, {"🐟","🐠"})
end

function Fish:init(game)
    self.game = game
    self.body = physics.body(CIRCLE, self.radius)
    self.body.position = self:randomOffscreenPosition()
    self.body.fixedRotation = true
    self.body.gravityScale = 0
    self.body.categories = {CATEGORY_FLOATING}
    self.body.mask = self.swimmingMask
    self.body.info = self
    self.image = randomElement(self.images)
    self.state = self.swimmingState
    
    self:startSwimmingTo(self:randomWaterPosition())
end

function Fish:isAlive()
    return self.body ~= nil
end

function Fish:destroy()
    self.body:destroy()
    self.body = nil
end

function Fish:draw()
    local function scalex(vel)
        if vel.x > 0 then
            return -1
        else
            return 1
        end
    end
    
    spriteMode(CENTER)
    pushMatrix()
    translate(self.body.position.x, self.body.position.y)
    if self.state == self.hookedState then
        translate(0, -16)
        rotate(-90)
    else
        scale(scalex(self.body.linearVelocity), 1)
    end
    translate(0, self.spriteYOffset)
    sprite(self.image, 0, 0)
    popMatrix()
    
    if DEBUG > 0 then
        local body = self.body
        
        ellipseMode(RADIUS)
        strokeWidth(4)
        stroke(0, 255, 0, 255)
        noFill()
        ellipse(body.x, body.y, body.radius)
        
        if self.state ~= self.hookedState then
            noStroke()
            fill(255, 0, 0, 255)
            ellipse(self.target.x, self.target.y, 4)
            strokeWidth(6)
            stroke(255, 0, 0, 255)
            line(body.x, body.y, self.target.x, self.target.y)
        end
    end
end

function Fish:startSwimmingTo(pos)
    self.target = pos
    
    local direction = (pos - self.body.position):normalize()
    local speed
    if self.state == self.escapedState then
        speed = self.maxSpeed * 5
    else
        speed = math.random(self.minSpeed, self.maxSpeed)
    end
    
    self.body.linearVelocity = direction * speed
end

function Fish:randomWaterPosition()
    return vec2(math.random(self.spacing, WIDTH-self.spacing),
                math.random(self.spacing, self.game.waterHeight-self.spacing))
end

function Fish:randomOffscreenPosition()
    return vec2(self.startX[math.random(1,2)],
                math.random(0, self.game.waterHeight-self.spacing))
end

function Fish:randomOffscreenPositionAwayFrom(fromPoint)
    local fromX = (fromPoint and fromPoint.x) or WIDTH/2
    
    local xIndex
    if self.body.x < fromX then
        xIndex = 1
    else
        xIndex = 2
    end
    return vec2(self.startX[xIndex],
                math.random(0, self.game.waterHeight-self.spacing))
end

function Fish:animate(dt)
    if self.state == self.escapedState and self:isOffscreen() then
        self.game:fishEscaped(self)
        self:destroy()
    elseif self.state ~= self.hookedState and self:needsNewTarget() then
        local pos
        if self.state == self.swimmingState then
            pos = self:randomWaterPosition()
        else
            pos = self:randomOffscreenPositionAwayFrom(vec2(WIDTH/2, HEIGHT/2))
        end
        
        self:startSwimmingTo(pos)
    end
end

function Fish:isOffscreen()
    return self.body.x < -self.radius or self.body.x >= WIDTH+self.radius
end

function Fish:needsNewTarget()
    local delta = self.target - self.body.position
    local v = self.body.linearVelocity
    
    return delta.x*v.x <= 0 or delta.y*v.y <= 0
end

function Fish:hooked(hooker)
    self.state = self.hookedState
    self.body.linearVelocity = 0
    self.body.position = hookPosition
    self.body.gravityScale = 0.5
end

function Fish:unhooked()
    self:swimAway(vec2(WIDTH/2, self.game.waterHeight/2))
    self.body.gravityScale = 0
end

function Fish:swimAway(dangerPoint)
    self.state = self.escapedState
    self:startSwimmingTo(self:randomOffscreenPositionAwayFrom(dangerPoint))
    self.body.mask = self.escapingMask
end
