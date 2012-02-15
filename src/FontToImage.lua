function glyphsToImage(args)
    pushStyle()
    
    font(args.font)
    fontSize(args.size)
    fill(args.fill)
    smooth()
    
    local sprite = image(textSize(args.glyphs))
    setContext(sprite)
    textMode(CORNER)
    text(args.glyphs, 0, 0)
    setContext()
    
    popStyle()
    
    return sprite
end

function emojiToImage(s, size)
    return glyphsToImage {
        glyphs=s, 
        font="AppleColorEmoji", 
        size=size or 40, 
        fill=color(255, 255, 255, 255)
    }
end
