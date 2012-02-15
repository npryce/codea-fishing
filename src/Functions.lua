-- Functions

function map(f, table)
    local result = {}
    for k,v in pairs(table) do
        result[k] = f(v)
    end
    return result
end

function fold(table, initial, combine)
    local result = initial
        
    for i, thing in pairs(table) do
        result = combine(result, thing)
    end
        
    return result
end

function wrap(x, min, max)
    if x < min then
        return max - (min - x)
    elseif x >= max then
        return min + (x - max)
    else
        return x
    end
end

function clamp(x, min, max)
    return math.max(min, math.min(max, x))
end

function clampMagnitude(x, maxMagnitude)
    return clamp(x, -maxMagnitude, maxMagnitude)
end

function invert(x)
    return -x
end

function blend(v1, v2, t)
    return v1 + (v2-v1)*clamp(t, 0, 1)
end

function blendColor(c1, c2, t)
    return color(
        blend(c1.r, c2.r, t),
        blend(c1.g, c2.g, t),
        blend(c1.b, c2.g, t),
        blend(c1.a, c2.a, t))
end

function alpha(c, newAlpha)
    return color(c.r, c.g, c.b, newAlpha)
end

function avg(x, y)
    return (x+y)/2
end

function randomElement(t)
    return t[math.random(#t)]
end

function subdivide(count, start, finish)
    local delta = (finish - start)/count
    local list = {start}
    
    for i = 1, count-2 do
        table.insert(list, start + i*delta)
    end
    table.insert(list, finish)
    
    return list
end


