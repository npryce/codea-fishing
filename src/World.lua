-- World

CATEGORY_EDGE = 1
CATEGORY_LINE = 2
CATEGORY_FLOATING = 3


function drawDock()
    local dockImage = "Planet Cute:Grass Block"
    local w, h = spriteSize(dockImage)
    
    for y = HEIGHT-30, HEIGHT-80, -40 do
        fillRow(dockImage, y, w)
    end
end

function fillRow(image, y, w)
    w = w or spriteSize(image)
    
    for x = 0, WIDTH+w-1, w do
        sprite(image, x, y)
    end
end

