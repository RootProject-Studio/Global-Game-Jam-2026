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
    
    obj.speed = 400
    obj.vx = 0
    obj.vy = 0
    obj.hp = 20
    obj.maxHp = 20
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
    
        -- cooldown pour les dégâts
    if self.hitCooldown and self.hitCooldown > 0 then
        self.hitCooldown = self.hitCooldown - dt
    end

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
    -- Dessin du joueur
    if self.image and self.image[self.currentFrame] then
        love.graphics.setColor(1, 1, 1)
        local img = self.image[self.currentFrame]
        local imgWidth = img:getWidth()
        local imgHeight = img:getHeight()
        local scaleX = (self.hitboxRadiusX * 2) / imgWidth
        local scaleY = (self.hitboxRadiusY * 2) / imgHeight
        love.graphics.draw(img, self.x, self.y, 0, scaleX, scaleY, imgWidth/2, imgHeight/2)
    end

    -- Barre de vie du joueur (en bas à droite)
    if self.maxHp and self.hp then
        local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
        local width = 200 * scale
        local height = 15 * scale
        local margin = 20 * scale

        local x0 = _G.gameConfig.windowWidth - width - margin - 100
        local y0 = _G.gameConfig.windowHeight - height - margin

        -- Fond rouge
        love.graphics.setColor(0.5,0,0)
        love.graphics.rectangle("fill", x0, y0, width, height)

        -- Vie verte
        love.graphics.setColor(0,1,0)
        love.graphics.rectangle("fill", x0, y0, width * (self.hp/self.maxHp), height)

        -- Contour noir
        love.graphics.setColor(0,0,0)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x0, y0, width, height)
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