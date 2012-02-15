-- Collections of game objects indexed by body (to work around bug in Codea v1.3)

do
    Group = class()
    Group.mortal = false
    
    function Group:init(...)
        self.things = {}
        self.count = 0
        for k, v in pairs({...}) do
            self:add(v)
        end
    end
    
    function Group:add(thing)
        self.things[thing.body] = thing
        self.count = self.count + 1
    end
    
    function Group:ownerOf(body)
        return self.things[body]
    end
    
    function Group:each(func)
        local function isAlive(a)
            return a.isAlive == nil or a:isAlive()
        end
        
        local lastFrame = self.things
        self.things = {}
        self.count = 0
        
        for body, thing in pairs(lastFrame) do
            if isAlive(thing) then
                func(thing)
                if isAlive(thing) then
                    self:add(thing)
                end
            end
        end
    end
    
    function Group:animate(dt)
        while dt > 0.1 do
            self:each(function (a) a:animate(0.1) end)
            dt = dt - 0.1
        end
        self:each(function (a) a:animate(dt) end)
    end
    
    function Group:draw()
        self:each(function (d) 
            pushMatrix()
            pushStyle()
            d:draw()
            popStyle()
            popMatrix()
        end)
    end
    
    function Group:bounds()
        local function mergeBounds(bounds, thing)
            return Bounds.merge(
                bounds, 
                thing.bounds ~= nil and thing:bounds())
        end
       
        return fold(self.things, nil, mergeBounds)
    end
    
    function Group:isEmpty()
        return self.count == 0
    end
    
    function Group:isAlive()
        return self.mortal and not self:isEmpty()
    end
end
