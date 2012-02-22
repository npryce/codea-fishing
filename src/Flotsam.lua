Flotsam = class()
Flotsam.floatingMask = {CATEGORY_LINE, CATEGORY_FLOATING, CATEGORY_EDGE}
Flotsam.hookedMask = {CATEGORY_LINE, CATEGORY_FLOATING}

function Flotsam.setup()
    Flotsam.bonuses = map(emojiToImage, {
        "🍎","🍊","🍉","🍓","💰", "🎁"})
    Flotsam.junk = map(emojiToImage, {
        "👟","👡", "👠", "👢", "⚽", "🎫", "💀", "🐚", 
        "🍁", "🌸", "🌺", "🍟",
        "🌂","🎺","👜","💼", "🎒"})
        
    Flotsam.images = Flotsam.junk
end

function Flotsam:init(game)
    self.game = game
    self.body = physics.body(CIRCLE, 20)
    self.body.info = self
    self.body.gravityScale = 0
    self.body.restitution = 0.5
    self.body.categories = {CATEGORY_FLOATING}
    self.body.mask = self.floatingMask
    
    self:launch()
end

function Flotsam:launch()
    self.image = randomElement(self.images)
    self.radius = math.max(self.image.width, self.image.height)
    self.radius = 16
    local pos = vec2(WIDTH+self.radius, 
                     math.random(self.radius, self.game.waterHeight-self.radius))
    local vel = vec2(-math.random(10, 50), 0)
    
    self.body.position = pos
    self.body.linearVelocity = vel
    self.hasBeenOnscreen = false
end

function Flotsam:animate(dt)
    local p = self.body.position
    
    if self.hooker then
        if p.y > (self.game.waterHeight+self.radius) then
            self.game:flotsamLanded(self)
        end
    elseif isOnscreen(p, self.radius) then
        self.hasBeenOnscreen = true
    elseif self.hasBeenOnscreen then
        self.game:flotsamEscaped(self, p)
    end 
end

function isOnscreen(p, r)
    return p.x + r >= 0 and p.x - r < WIDTH
       and p.y + r >= 0 and p.y - r < HEIGHT
end

function Flotsam:hooked(hooker)
    self.hooker = hooker
    self.body.mask = self.hookedMask
    self.body.linearVelocity = 0
end

function Flotsam:unhooked()
    self.hooker = nil
    self.body.mask = self.floatingMask
end

function Flotsam:draw()
    spriteMode(CENTER)
    sprite(self.image, self.body.x, self.body.y-8)
end

function Flotsam:drawDebug()
    ellipseMode(RADIUS)
    strokeWidth(4)
    stroke(0, 255, 0, 255)
    noFill()
    ellipse(self.body.x, self.body.y, self.body.radius)
end

function Flotsam:destroy()
    self.body:destroy()
end


