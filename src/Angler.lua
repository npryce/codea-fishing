Angler = class()

Angler.divisions = 25
Angler.maxVelocity = vec2(WIDTH/2,0)
Angler.reelTime = 0.5 -- time in secs to reel fully in or out
Angler.radius = 40

function Angler:init(pos)
    self.maxLength = pos.y
    self.length = self.maxLength/2
    self.reelRate = 0
    local linkLength = self.length/self.divisions
    
    local anglerBody = physics.body(CIRCLE, 1)
    anglerBody.type = KINEMATIC
    anglerBody.position = pos
    
    self.bodies = {anglerBody}
    
    for i = 1, self.divisions do
        local body = physics.body(CIRCLE, 1)
        body.position = vec2(pos.x, pos.y - (i*linkLength))
        body.linearDamping = 0.75
        body.angularDamping = 0.75
        body.categories = {CATEGORY_LINE}
        body.mask = {CATEGORY_FLOATING}
        
        table.insert(self.bodies, body)
    end
    
    self.hook = self.bodies[self.divisions]
    self.hook.radius = 5
    self.hook.density = 2
    
    self.joints = {}
    
    for i = 1, self.divisions-1 do
        local body1 = self.bodies[i]
        local body2 = self.bodies[i+1]
        
        local joint = physics.joint(DISTANCE, body1, body2, 
            body1.position, body2.position)
        joint.frequency = 30
        joint.dampingRatio = 100
        
        table.insert(self.joints, joint)
    end
end

function Angler:hookPosition()
    return self.hook.position
end

function Angler:destroy()
    if self.hookJoint then
        self.hookJoint:destroy()
    end
    for _, joint in pairs(self.joints) do
        joint:destroy()
    end
    for _, body in pairs(self.bodies) do
        body:destroy()
    end
end

function Angler:steer(steerX)
    self.bodies[1].linearVelocity = steerX * self.maxVelocity
end

function Angler:reel(amount)
    self.reelRate = amount * (self.maxLength/self.reelTime)
end

function Angler:animate(dt)
    self:clampWithinScreen()
    if self.reelRate ~= 0 then
        self:reelLine(dt)
    end
end

function Angler:reelLine(dt)
    self.length = clamp(self.length + self.reelRate*dt, 0, self.maxLength)
    local linkLength = self.length/self.divisions
    
    for k, joint in pairs(self.joints) do
        joint.length = linkLength
    end
end

function Angler:clampWithinScreen(dt)
    self.bodies[1].x = clamp(self.bodies[1].x, self.radius, WIDTH-self.radius)
end

function Angler:catch(thing)
    if self.caught then
        self:releaseCaught()
    end
    
    thing:hooked(self)
    
    self.caught = thing
    self.hookJoint = physics.joint(DISTANCE, 
        self.hook, thing.body, self.hook.position, thing.body.position)
    self.hookJoint.distance = 0
    self.hookJoint.frequency = 30
    self.hookJoint.dampingRatio = 100
end

function Angler:maybeRelease(thing)
    if thing == self.caught then
        self:releaseCaught()
    end
end

function Angler:releaseCaught()
    self.hookJoint:destroy()
    self.hookJoint = nil
    self.caught:unhooked()
    self.caught = nil
end

function Angler:draw()
    pushMatrix()
    pushStyle()
    
    smooth()
    noFill()
    
    spriteMode(CENTER)
    sprite("Planet Cute:Character Boy", 
           self.bodies[1].x, self.bodies[1].y + 40)
    
    stroke(255, 255, 255, 255)
    strokeWidth(6)
    lineCapMode(PROJECT)
        
    for k, joint in pairs(self.joints) do
        line(joint.anchorA.x, joint.anchorA.y,
             joint.anchorB.x, joint.anchorB.y)
    end
    
    pushMatrix()
    translate(self.hook.x, self.hook.y)
    if self.hookJoint then
        local j = self.hookJoint
        local d = j.anchorB - j.anchorA
        local a = vec2(0,-1):angleBetween(d)
        rotate(math.deg(a))
    end
    sprite("Tyrian Remastered:Organic Claw", 0, -10)
    popMatrix()
    
    popStyle()
    popMatrix()
end

function Angler:drawDebug()
    ellipseMode(RADIUS)
    fill(255, 0, 0, 255)
    stroke(255, 0, 0, 255)
    noStroke()
        
    ellipse(self.hook.x, self.hook.y, self.hook.radius)
end

