Particle = class()

function Particle:init(args)
    self.pos = args.pos
    self.vel = args.vel or vec2(0,0)
    local acc = args.acc or vec2(0, 0)
    self.accMagnitude = acc:len()
    self.accDirection = acc/self.accMagnitude
    self.drag = args.drag or 0
    self.lifespan = args.lifespan or 1
    self.isAlive = args.isAlive
    self.initialColor = args.initialColor or color(242, 221, 41, 255)
    self.finalColor = args.finalColor or color(128, 37, 28, 255)
    self.age = 0
end

-- default, can be overridden by constructor parameter
function Particle:isAlive()
    return self.age <= self.lifespan
end

function Particle:draw()
    local c = blendColor(self.initialColor, self.finalColor, 
                         self.age/self.lifespan)
    
    fill(c)
    stroke(c)
    noStroke()
    ellipseMode(CENTER)
    smooth()
    
    ellipse(self.pos.x, self.pos.y, 5, 5)
end

function Particle:animate(dt)
    -- emulate skin friction
    
    local accMagnitude = math.max(0, self.accMagnitude - self.drag * self.vel:lenSqr())
    local acc = self.accDirection*accMagnitude
    
    self.age = self.age + dt
    self.pos = self.pos + self.vel*dt + 0.5*acc*(dt^2)
    self.vel = self.vel + acc*dt
end