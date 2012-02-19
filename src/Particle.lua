Particle = class()

function Particle:init(args)
    self.pos = args.pos
    self.vel = args.vel or vec2(0,0)
    self.lifespan = args.lifespan or 1
    self.age = 0
    self.initialColor = args.initialColor or color(242, 221, 41, 255)
    self.finalColor = args.finalColor or color(128, 38, 29, 0)
end

function Particle:draw()
    local c = blendColor(self.initialColor, self.finalColor, 
                         self.age/self.lifespan)
    
    fill(c)
    stroke(c)
    noStroke()
    rectMode(CENTER)
    
    rect(self.pos.x, self.pos.y, 3, 3)
end

function Particle:isAlive()
    return self.age <= self.lifespan
end

function Particle:animate(dt)
    self.age = self.age + dt
    self.pos = self.pos + self.vel*dt
end