All = class(Controller)

function All:init(args)
    self.controllers = args
end

function All:touched(t)
    for _, c in pairs(self.controllers) do
        c:touched(t)
    end
end

function All:draw()
    for _, c in pairs(self.controllers) do
        c:draw()
    end
end
