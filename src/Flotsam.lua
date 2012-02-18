Flotsam = class()
Flotsam.floatingMask = {CATEGORY_LINE, CATEGORY_FLOATING, CATEGORY_EDGE}
Flotsam.hookedMask = {CATEGORY_LINE, CATEGORY_FLOATING}
Flotsam.radius = 20

function Flotsam.setup()
    Flotsam.bonuses = map(emojiToImage, {
        "🍎","🍊","🍉","🍓","💰", "🎁"})
    Flotsam.junk = map(emojiToImage, {
        "👟","👡", "👠", "👢", "⚽", "🎫", "💀", "🐚", 
        "🍁", "🌸", "🌺", "🍟",
        "🌂","🎺","👜","💼", "🎒"})
end

function Flotsam:init(game)
    self.game = game
    self.body = physics.body(CIRCLE, 20)
    self.body.info = self
    self.body.gravityScale = 0
    self.body.restitution = 0.5
    self.body.categories = {CATEGORY_FLOATING}
    self.body.mask = self.floatingMask
    
    self:relaunch()
end

function Flotsam:relaunch()
    local pos = vec2(WIDTH+self.radius, 
                     math.random(self.radius, self.game.waterHeight-self.radius))
    local vel = vec2(-math.random(10, 50), 0)
    
    self:launch(pos, vel)
end

function Flotsam:launch(pos, vel)
    self.body.position = pos
    self.body.linearVelocity = vel
    
    self.isBonus = math.random() < 0.1
    
    local type
    if self.isBonus then
        type = Flotsam.bonuses
    else
        type = Flotsam.junk
    end
    self.image = randomElement(type)
    
    self.hasBeenOnscreen = false
end

function Flotsam:draw()
    spriteMode(CENTER)
    sprite(self.image, self.body.x, self.body.y-8)
    
    if DEBUG > 0 then
        ellipseMode(RADIUS)
        strokeWidth(4)
        stroke(0, 255, 0, 255)
        noFill()
        ellipse(self.body.x, self.body.y, self.body.radius)
        
        if not isOnscreen(self.body.position, -self.radius) then
            stroke(255, 246, 0, 178)
            strokeWidth(5)
            line(WIDTH/2, HEIGHT/2, self.body.x, self.body.y)
        end
    end
end

function Flotsam:animate(dt)
    local p = self.body.position
    
    if self.hooker then
        if p.y > (self.game.waterHeight+self.radius) then
            self.game:flotsamLanded(self)
        end
    else
        if self.hasBeenOnscreen or self.body.linearVelocity.x >= 0 then
            if not isOnscreen(p, -self.radius) then
                self.game:flotsamEscaped(self)
                self:relaunch()
            end
        else
            self.hasBeenOnScreen = isOnscreen(p, self.radius)
        end
    end 
end

function isOnscreen(p, r)
    return p.x >= r and p.x < WIDTH-r
       and p.y >= r and p.y < HEIGHT-r
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

function Flotsam:destroy()
    self.body:destroy()
end


