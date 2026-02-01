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
    
    -- Propriété pour le mask équipé (initialisé vide)
    obj.equippedMask = nil
    
    -- Propriétés pour les projectiles (système générique)
    obj.projectiles = {}  -- Liste des projectiles actifs (lasers, flèches, etc.)
    
    return obj
end

function Pedro:update(dt, roomContext)

    -- Bloquer le joueur si un shop est ouvert
    if roomContext.mobs then
        for _, mob in ipairs(roomContext.mobs) do
            if mob.subtype == "traider" and mob.shopOpen then
                -- Player cannot move while shop is open
                self.vx = 0
                self.vy = 0
                return
            end
        end
    end
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

    if love.keyboard.isDown(keys.shoot_up) then
        self:shoot(0, -1, roomContext)  -- Tir vers le haut
    elseif love.keyboard.isDown(keys.shoot_down) then
        self:shoot(0, 1, roomContext)   -- Tir vers le bas
    end

    if love.keyboard.isDown(keys.shoot_left) then
        self:shoot(-1, 0, roomContext)  -- Tir vers la gauche
    elseif love.keyboard.isDown(keys.shoot_right) then
        self:shoot(1, 0, roomContext)   -- Tir vers la droite
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
    
    -- Mettre à jour les projectiles
    self:updateProjectiles(dt)
    
    -- Mettre à jour le mask équipé
    if self.equippedMask and self.equippedMask.update then
        self.equippedMask:update(dt, self)
    end
end

function Pedro:shoot(dirX, dirY, roomContext)
    -- Déléguer le tir au mask équipé
    if not self.equippedMask then
        return
    end
    
    -- Si le mask a une méthode shoot, l'utiliser
    if self.equippedMask.shoot then
        return self.equippedMask:shoot(self, dirX, dirY, roomContext)
    end
end

function Pedro:addProjectile(projectile)
    -- Ajouter un projectile à la liste (utilisé par les masks)
    table.insert(self.projectiles, projectile)
end

function Pedro:updateProjectiles(dt)
    -- Mettre à jour et supprimer les projectiles qui ont dépassé leur distance
    local i = 1
    while i <= #self.projectiles do
        local proj = self.projectiles[i]
        
        -- Si c'est un rayon, ne pas le déplacer (il reste à la position du joueur)
        if not proj.isRay then
            -- Déplacer le projectile normal
            proj.x = proj.x + proj.dirX * proj.speed * dt
            proj.y = proj.y + proj.dirY * proj.speed * dt
            
            -- Augmenter la distance parcourue
            proj.distance = proj.distance + proj.speed * dt
            
            -- Supprimer si dépassé la distance max
            if proj.distance > proj.maxDistance then
                table.remove(self.projectiles, i)
            else
                i = i + 1
            end
        else
            -- Les rayons suivent la position des yeux du joueur et sont supprimés après un court délai
            if proj.player then
                -- Décaler depuis le centre du joueur vers les yeux (20 pixels dans la direction du tir)
                local eyeOffsetDistance = 20
                proj.x = proj.player.x + proj.dirX * eyeOffsetDistance
                proj.y = proj.player.y + proj.dirY * eyeOffsetDistance
            end
            
            proj.timer = (proj.timer or 0.2) - dt
            if proj.timer <= 0 then
                table.remove(self.projectiles, i)
            else
                i = i + 1
            end
        end
    end
end

function Pedro:checkProjectileCollisions(enemies)
    -- Vérifier les collisions entre les projectiles et les ennemis
    -- Cette méthode fonctionne pour TOUS les types de projectiles
    for projIdx = #self.projectiles, 1, -1 do
        local proj = self.projectiles[projIdx]
        if not proj.hit then  -- Vérifier si le projectile n'a pas déjà touché
            
           for mobIdx = #enemies, 1, -1 do
                local mob = enemies[mobIdx]
                if not mob then goto continue_mob end
                if mob.state == "underground" then goto continue_mob end
                if not mob.isDead or not mob:isDead() then
                    -- Convertir la position relative du mob en pixels absolus
                    local mobX = mob.relX * proj.roomWidth + proj.roomX
                    local mobY = mob.relY * proj.roomHeight + proj.roomY
                    
                    local collides = false
                    
                    if proj.isRay then
                        -- Pour les rayons : vérifier si le mob est sur la ligne du rayon
                        local rayEndX = proj.x + proj.dirX * (proj.length or 400)
                        local rayEndY = proj.y + proj.dirY * (proj.length or 400)
                        
                        -- Distance entre le mob et la ligne du rayon
                        local dx = rayEndX - proj.x
                        local dy = rayEndY - proj.y
                        local rayLen = math.sqrt(dx*dx + dy*dy)
                        
                        if rayLen > 0 then
                            -- Produit scalaire pour projeter le mob sur la ligne
                            local t = ((mobX - proj.x) * dx + (mobY - proj.y) * dy) / (rayLen * rayLen)
                            
                            -- Clamp t pour être sur le segment du rayon
                            t = math.max(0, math.min(1, t))
                            
                            -- Point le plus proche sur le rayon
                            local closestX = proj.x + t * dx
                            local closestY = proj.y + t * dy
                            
                            -- Distance entre le mob et le point le plus proche
                            local distX = mobX - closestX
                            local distY = mobY - closestY
                            local dist = math.sqrt(distX*distX + distY*distY)
                            
                            -- Collision si distance < rayon du mob + largeur du rayon
                            if dist < mob.size + (proj.width or 30) / 2 then
                                collides = true
                            end
                        end
                    else
                        -- Pour les projectiles normaux : simple détection de distance
                        local projRadius = proj.radius or 5
                        local dx = proj.x - mobX
                        local dy = proj.y - mobY
                        local dist = math.sqrt(dx * dx + dy * dy)
                        
                        if dist < projRadius + mob.size then
                            collides = true
                        end
                    end
                    
                    -- Si collision détectée
                    if collides then
                        -- Pour les rayons, vérifier s'on a déjà touché cet ennemi
                        if proj.isRay then
                            if not proj.hitEnemies[mob] then
                                -- Infliger les dégâts
                                if proj.onHit then
                                    proj:onHit(mob)
                                else
                                    mob:takeDamage(proj.damage or 10)
                                end
                                -- Marquer cet ennemi comme touché par ce rayon
                                proj.hitEnemies[mob] = true
                            end
                        else
                            -- Pour les projectiles normaux
                            -- Invoquer le callback de collision du projectile si disponible
                            if proj.onHit then
                                proj:onHit(mob)
                            else
                                -- Sinon, infliger les dégâts par défaut
                                mob:takeDamage(proj.damage or 10)
                            end
                            
                            -- Marquer le projectile comme ayant touché
                            proj.hit = true
                            
                            -- Supprimer immédiatement les projectiles normaux
                            table.remove(self.projectiles, projIdx)
                            break
                        end
                    end
                end
                   ::continue_mob:: 
                 end
            
        end
    end
end

function Pedro:drawProjectiles()
    -- Dessiner tous les projectiles (système générique)
    for _, proj in ipairs(self.projectiles) do
        -- Si c'est un rayon laser
        if proj.isRay then
            -- Dessiner le rayon comme une ligne épaisse brillante
            love.graphics.setColor(1, 0.3, 0.3, 0.8)  -- Rouge semi-transparent
            love.graphics.setLineWidth(proj.width or 30)
            local endX = proj.x + proj.dirX * (proj.length or 400)
            local endY = proj.y + proj.dirY * (proj.length or 400)
            love.graphics.line(proj.x, proj.y, endX, endY)
            
            -- Ajouter une lueur/core blanc au centre du rayon
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.setLineWidth((proj.width or 30) * 0.5)
            love.graphics.line(proj.x, proj.y, endX, endY)
        elseif proj.draw then
            -- Si le projectile a une méthode draw custom, l'utiliser
            proj:draw()
        else
            -- Sinon, dessiner un projectile normal (petit laser)
            love.graphics.setColor(1, 0, 0)  -- Rouge
            local projWidth = proj.width or 5
            love.graphics.setLineWidth(projWidth)
            love.graphics.line(proj.x, proj.y, proj.x + proj.dirX * 20, proj.y + proj.dirY * 20)
        end
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
    
    -- Dessiner les projectiles
    self:drawProjectiles()

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

function Pedro:equipMask(mask)
    -- Équiper un mask
    self.equippedMask = mask
    if mask and mask.onEquip then
        mask:onEquip(self)
    end
end

function Pedro:unequipMask()
    -- Déséquiper le mask actuel
    if self.equippedMask and self.equippedMask.onUnequip then
        self.equippedMask:onUnequip(self)
    end
    self.equippedMask = nil
end

function Pedro:getMaskDamageBonus()
    -- Retourner les dégâts bonus du mask équipé
    if self.equippedMask and self.equippedMask.getDamageBonus then
        return self.equippedMask:getLifeBonus()
    end
    return 0
end

return Pedro