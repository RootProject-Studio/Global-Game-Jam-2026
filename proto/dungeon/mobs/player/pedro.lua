local Mob = require("dungeon.mobs.mob")

local Pedro = setmetatable({}, Mob)
Pedro.__index = Pedro

function Pedro:new()
    local obj = setmetatable({}, self)
    
    -- Initialiser les propriétés de Mob directement
    obj.x = 400
    obj.y = 300
    obj.width = 64    
    obj.height = 64   
    obj.size = 32     
    
    -- Propriétés de la hitbox elliptique
    obj.hitboxRadiusX = 50  -- Rayon horizontal (plus long gauche-droite)
    obj.hitboxRadiusY = 30  -- Rayon vertical (plus court haut-bas)
    
    obj.speed = 200
    obj.vx = 0
    obj.vy = 0
    obj.hp = 100
    obj.maxHp = 100
    obj.type = "player"
    
    -- Propriétés spécifiques à Pedro
    obj.currentFrame = 1
    obj.frameTime = 0
    obj.frameDelay = 0.1
    
    -- Charger les images du joueur
    obj.image = {
        love.graphics.newImage("dungeon/mobs/player/assets/pedro1.png"),
        love.graphics.newImage("dungeon/mobs/player/assets/pedro2.png")
    }
    
    return obj
end

function Pedro:update(dt)
    -- Récupérer les touches enfoncées
    local keys = _G.gameConfig.keys
    
    -- Réinitialiser la vélocité
    self.vx = 0
    self.vy = 0
    
    -- Variable pour savoir si le joueur bouge
    local isMoving = false
    
    -- Gestion du mouvement
    if love.keyboard.isDown(keys.up) then
        self.vy = -self.speed
        isMoving = true
    elseif love.keyboard.isDown(keys.down) then
        self.vy = self.speed
        isMoving = true
    end
    
    if love.keyboard.isDown(keys.left) then
        self.vx = -self.speed
        isMoving = true
    elseif love.keyboard.isDown(keys.right) then
        self.vx = self.speed
        isMoving = true
    end
    
    -- Appliquer le mouvement
    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt
    
    -- Mettre à jour l'animation seulement si le joueur bouge
    if isMoving then
        self.frameTime = self.frameTime + dt
        if self.frameTime >= self.frameDelay then
            self.frameTime = 0
            self.currentFrame = self.currentFrame + 1
            if self.currentFrame > #self.image then
                self.currentFrame = 1
            end
        end
    else
        -- Réinitialiser à la première frame si le joueur ne bouge pas
        self.frameTime = 0
        self.currentFrame = 1
    end
end

function Pedro:draw()
    if self.image and self.image[self.currentFrame] then
        love.graphics.setColor(1, 1, 1)
        -- Dessiner l'image centrée à la position du joueur
        -- Récupérer la taille de l'image originale
        local img = self.image[self.currentFrame]
        local imgWidth = img:getWidth()
        local imgHeight = img:getHeight()
        
        -- Calculer l'échelle pour adapter l'image à la taille de la hitbox
        local scaleX = (self.hitboxRadiusX * 2) / imgWidth  -- Utiliser la hitbox elliptique
        local scaleY = (self.hitboxRadiusY * 2) / imgHeight -- Utiliser la hitbox elliptique
        
        -- Dessiner l'image centrée sur la position (centre de la hitbox)
        love.graphics.draw(
            img,
            self.x,                   -- Position X (centre de la hitbox)
            self.y,                   -- Position Y (centre de la hitbox)
            0,                         -- Rotation
            scaleX,                    -- Scale X
            scaleY,                    -- Scale Y
            imgWidth / 2,              -- Origin X (centre de l'image)
            imgHeight / 2              -- Origin Y (centre de l'image)
        )
    end
end

function Pedro:getPosition()
    return self.x, self.y
end

function Pedro:setPosition(x, y)
    self.x = x
    self.y = y
end

function Pedro:getBounds()
    return self.x, self.y, self.width, self.height
end

function Pedro:getHitbox()
    -- Retourner les propriétés de la hitbox elliptique
    return {
        x = self.x,
        y = self.y,
        radiusX = self.hitboxRadiusX,
        radiusY = self.hitboxRadiusY
    }
end

function Pedro:isCollidingWithPoint(px, py)
    -- Vérifier si un point est à l'intérieur de l'ellipse
    local dx = (px - self.x) / self.hitboxRadiusX
    local dy = (py - self.y) / self.hitboxRadiusY
    return (dx * dx + dy * dy) <= 1
end

function Pedro:isCollidingWithRect(rx, ry, rw, rh)
    -- Vérifier si la hitbox elliptique collisionne avec un rectangle
    -- Trouver le point le plus proche du centre de l'ellipse dans le rectangle
    local closestX = math.max(rx, math.min(self.x, rx + rw))
    local closestY = math.max(ry, math.min(self.y, ry + rh))
    
    -- Vérifier si ce point est dans l'ellipse
    return self:isCollidingWithPoint(closestX, closestY)
end

return Pedro