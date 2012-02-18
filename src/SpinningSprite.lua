SpinningSprite = class()
SpinningSprite.lifespan = 1
SpinningSprite.angularVelocity = 360*3 -- degrees/sec

function SpinningSprite:init(image, startPos, endPos)
    self.image = image
    self.start = startPos
    self.vec = endPos - startPos
    self.age = 0
end

function SpinningSprite:animate(dt)
    self.age = math.min(self.age + dt, self.lifespan)
end

function SpinningSprite:isAlive()
    return self.age < self.lifespan
end

function SpinningSprite:draw()
    local ageRatio = self.age/self.lifespan
    local p = self.start + self.vec * ageRatio
    
    translate(p.x, p.y)
    rotate(self.age * self.angularVelocity)
    tint(255, 255, 255, (1-ageRatio)*255)
    spriteMode(CENTER)
    sprite(self.image, 0, 0)
end
