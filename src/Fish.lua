Fish = class()
Fish.radius = 20
Fish.spacing = 2*Fish.radius
Fish.minSpeed = 25
Fish.maxSpeed = 100
Fish.spriteYOffset = -8 -- to compensate for emoji font
Fish.swimmingMask = {CATEGORY_LINE, CATEGORY_FLOATING}
Fish.escapingMask = {CATEGORY_FLOATING}


function Fish.setup()
    Fish.images = map(emojiToImage, {"🐟","🐠"})
    Fish.startX = {-Fish.spacing, WIDTH+Fish.spacing}
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

function Fish:hookSensorRadius()
    return self.radius * self.game.caughtCount
end

function Fish:destroy()
    self.body:destroy()
    self.body = nil
end

function Fish:startSwimmingTo(pos)
    self.target = pos
    
    local direction = (pos - self.body.position):normalize()
    local speed = self.state.speed(self)
    self.body.linearVelocity = direction * speed
end


function Fish:asNearTheHookAsPossible()
    local hookp = self.game:hookPosition()
    
    return vec2(clamp(hookp.x, 0, WIDTH), 
                clamp(hookp.y, 0, self.game.waterHeight))
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
    self.state.animate(self)
end

function Fish:animateWhenSwimming()
    if self:needsNewTarget() then
        self:startSwimmingTo(self:newTarget())
    end
end

function Fish:newTarget()
    if self:canSenseHook() then
        return self:asNearTheHookAsPossible()
    else
        return self:randomWaterPosition()
    end
end

-- A bit of a hack: the behaviour in the AttractMode should really be modelled by a
-- distinct state
function Fish:canSenseHook()
    if self.game.hookPosition then
        local distanceToHookSq = self.body.position:distSqr(self.game:hookPosition())
        return distanceToHookSq <= self:hookSensorRadius()^2
    else
        return false
    end
end

function Fish:animateWhenEscaping()
    if self:isOffscreen() then
        self.game:fishEscaped(self)
        self:destroy()
    elseif self:needsNewTarget() then
        self:startSwimmingTo(
            self:randomOffscreenPositionAwayFrom(vec2(WIDTH,HEIGHT)/2))
    end
end

function Fish:animateWhenHooked()
    -- just hang in there!
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
    self:swimAwayFrom(vec2(WIDTH/2, self.game.waterHeight/2))
    self.body.gravityScale = 0
    sound(DATA, "ZgNANwBFRH8ETkBmHT8PPgAAgD8AAIA/MQB7WjgALz5/P1s3")
end

function Fish:swimAwayFrom(dangerPoint)
    self.state = self.escapingState
    self:startSwimmingTo(
        self:randomOffscreenPositionAwayFrom(dangerPoint))
    self.body.mask = self.escapingMask
end

function Fish:randomLeisurelySpeed()
    return math.random(self.minSpeed, self.maxSpeed)
end

function Fish:madDashSpeed()
    return self.maxSpeed * 5
end

Fish.swimmingState = {
    xflip = -1,
    drawDebugTarget = true,
    speed = Fish.randomLeisurelySpeed,
    animate = Fish.animateWhenSwimming
}

Fish.hookedState = {
    xflip = 1,
    drawDebugTarget = false,
    speed = function(fish) return 0 end,
    animate = Fish.animateWhenHooked
}

Fish.escapingState = {
    xflip = -1,
    drawDebugTarget = true,
    speed = Fish.madDashSpeed,
    animate = Fish.animateWhenEscaping
}

function Fish:draw()
    local function scalex(vel)
        if vel.x > 0 then
            return 1
        else
            return -1
        end
    end
    
    spriteMode(CENTER)
    pushMatrix()
    translate(self.body.position.x, self.body.position.y)
    
    local sx = self.state.xflip * scalex(self.body.linearVelocity)
    scale(sx, 1)
    translate(0, self.spriteYOffset)
    sprite(self.image, 0, 0)
    popMatrix()
end

function Fish:drawDebug()
    local body = self.body
        
    ellipseMode(RADIUS)
    noFill()
    strokeWidth(4)
    stroke(0, 255, 0, 255)
    ellipse(body.x, body.y, body.radius)
    stroke(255, 255, 0, 255)
    ellipse(body.x, body.y, self:hookSensorRadius())
    
    if self.state.drawDebugTarget then
        noStroke()
        fill(255, 0, 0, 255)
        ellipse(self.target.x, self.target.y, 4)
        strokeWidth(6)
        stroke(255, 0, 0, 255)
        line(body.x, body.y, self.target.x, self.target.y)
    end
end

