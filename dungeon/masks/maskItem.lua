local MaskItem = {}
MaskItem.__index = MaskItem

function MaskItem:new(maskType, relX, relY)
    local self = setmetatable({}, MaskItem)
    self.maskType = maskType  -- "cyclope", "ffp2", "scream"
    self.relX = relX          -- position relative à la salle (0-1)
    self.relY = relY
    self.size = 15            -- taille de la hitbox
    self.bobSpeed = 2         -- vitesse du mouvement de bob
    self.bobAmount = 10       -- amplitude du mouvement vertical
    self.bobOffset = 0
    self.rotation = 0
    self.collected = false
    
    -- Charger le sprite du masque
    self.sprite = self:loadSprite()
    
    return self
end

function MaskItem:loadSprite()
    -- Mapper les types de masques à leurs sprites
    local spritePath = {
        cyclope = "dungeon/masks/assets/cyclope.png",
        ffp2 = "dungeon/masks/assets/ffp2.png",
        scream = "dungeon/masks/assets/scream.png",
        anonymous = "dungeon/masks/assets/anonymous.png",
        anubis = "dungeon/masks/assets/anubis.png",
        hydre = "dungeon/masks/assets/hydre.png",
        luchador = "dungeon/masks/assets/luchador.png",
        magrit = "dungeon/masks/assets/magrit.png",
        paladin = "dungeon/masks/assets/paladin.png",
        plague = "dungeon/masks/assets/plague.png",
    }
    
    local path = spritePath[self.maskType]
    if path and love.filesystem.getInfo(path) then
        return love.graphics.newImage(path)
    end
    return nil
end

function MaskItem:update(dt)
    if self.collected then return end
    
    -- Animation de bob (haut/bas)
    self.bobOffset = math.sin(love.timer.getTime() * self.bobSpeed) * self.bobAmount
    
    -- Rotation lente
    self.rotation = self.rotation + dt * 2
    if self.rotation > math.pi * 2 then
        self.rotation = 0
    end
end

function MaskItem:draw(roomContext)
    if self.collected then return end
    
    local roomX = roomContext.roomX
    local roomY = roomContext.roomY
    local roomW = roomContext.roomWidth
    local roomH = roomContext.roomHeight
    local scale = roomContext.scale or 1
    
    -- Position absolue
    local x = roomX + self.relX * roomW
    local y = roomY + self.relY * roomH + (self.bobOffset * scale)
    
    -- Dessiner le sprite avec rotation
    love.graphics.setColor(1, 1, 1)
    if self.sprite then
        local img = self.sprite
        local imgWidth = img:getWidth()
        local imgHeight = img:getHeight()

        local targetSize = self.size * scale * 2 * 3
        local scaleUniform = targetSize / math.max(imgWidth, imgHeight)
        -- local scaleX = targetSize / imgWidth
        -- local scaleY = targetSize / imgHeight

        love.graphics.draw(
            img,
            x, y,
            self.rotation,
            scaleUniform,
            scaleUniform,
            imgWidth / 2,
            imgHeight / 2
        )
    else
        -- Fallback si pas de sprite
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("fill", x, y, self.size * scale)
    end
    
    -- Lueur optionnelle
    love.graphics.setColor(1, 1, 0, 0.3)
    love.graphics.circle("line", x, y, self.size * scale + 5)
end

function MaskItem:getAbsolutePos(roomContext)
    local roomX = roomContext.roomX
    local roomY = roomContext.roomY
    local roomW = roomContext.roomWidth
    local roomH = roomContext.roomHeight
    
    return {
        x = roomX + self.relX * roomW,
        y = roomY + self.relY * roomH + (self.bobOffset * (roomContext.scale or 1)),
        r = self.size * (roomContext.scale or 1)
    }
end

function MaskItem:collect()
    self.collected = true
end

function MaskItem:isDead()
    return self.collected
end

return MaskItem