Banner = class()

Banner.fadeIn = {
    duration = 1,
    alpha = function(ratio) return ratio end,
    indexInc = 0
}
Banner.solid = {
    duration = 5,
    alpha = function(ratio) return 1 end,
    indexInc = 0
}
Banner.fadeOut = {
    duration = 1,
    alpha = function(ratio) return 1-ratio end,
    indexInc = 1
}
Banner.fadeIn.next = Banner.solid
Banner.solid.next = Banner.fadeOut
Banner.fadeOut.next = Banner.fadeIn

function Banner:init(args)
    self.pos = args.pos
    self.lines = args.lines
    self.font = args.font
    self.fontSize = args.fontSize
    self.fill = args.fill
    
    self.lineIndex = 1
    self.state = self.solid
    self.timer = self.state.duration
end

function Banner:animate(dt)
    local rem = self.timer - dt
    if rem > 0 then
        self.timer = rem
    else
        self.lineIndex = self.lineIndex + self.state.indexInc
        if self.lineIndex > #self.lines then
            self.lineIndex = 1
        end
        self.state = self.state.next
        self.timer = self.state.duration
        self:animate(-rem)
    end  
end

function Banner:draw()
    local ratio = 1 - self.timer/self.state.duration
    
    fill(alpha(self.fill, 255*self.state.alpha(ratio)))
    font(self.font)
    fontSize(self.fontSize)
    textMode(CENTER)
    text(self.lines[self.lineIndex], self.pos.x, self.pos.y)
end
