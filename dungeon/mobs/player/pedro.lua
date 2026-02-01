local Mob = require("dungeon.mobs.mob")
local MaskManager = require("dungeon.masks.mask_manager")

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
    obj.facing = "right"  -- par défaut à droite

    
    -- Charger les images du joueur
    obj.image = {
        love.graphics.newImage("dungeon/mobs/player/assets/pedro1.png"),
        love.graphics.newImage("dungeon/mobs/player/assets/pedro2.png")
    }
    
    -- Propriété pour le mask équipé (initialisé vide)
    obj.equippedMask = nil
    obj.maskManager = MaskManager:new()

    -- Propriétés pour les projectiles (système générique)
    obj.projectiles = {}  -- Liste des projectiles actifs (lasers, flèches, etc.)
    
    return obj
end

function Pedro:update(dt, roomContext)
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
        self.facing = "left"
    elseif love.keyboard.isDown(keys.right) then
        self.vx = self.speed
        isMoving = true
        self.facing = "right"
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
    
    -- Mettre à jour les masques actifs
    for i, mask in ipairs(self.maskManager.slots) do
        if mask and mask.update then
            mask:update(dt, self)
        end
    end

end

function Pedro:shoot(dirX, dirY, roomContext)
    for i, mask in ipairs(self.maskManager.slots) do
        if mask and mask.shoot then
            mask:shoot(self, dirX, dirY, roomContext)
        end
    end
end



function Pedro:addProjectile(projectile)
    -- Ajouter un projectile à la liste (utilisé par les masks)
    table.insert(self.projectiles, projectile)
end

function Pedro:updateProjectiles(dt)
    local i = 1
    while i <= #self.projectiles do
        local proj = self.projectiles[i]
        
        if proj.isOrb then
            -- Les orbes orbitent autour du joueur
            if proj.player then
                proj.angle = proj.angle + proj.orbitSpeed * dt
                proj.x = proj.player.x + math.cos(proj.angle) * proj.orbitRadius
                proj.y = proj.player.y + math.sin(proj.angle) * proj.orbitRadius
                
                for enemy, cooldown in pairs(proj.hitCooldowns) do
                    proj.hitCooldowns[enemy] = cooldown - dt
                    if proj.hitCooldowns[enemy] <= 0 then
                        proj.hitCooldowns[enemy] = nil
                    end
                end
            end
            
            proj.timer = proj.timer - dt
            if proj.timer <= 0 then
                table.remove(self.projectiles, i)
            else
                i = i + 1
            end
        elseif proj.isHeal then
            -- Les effets de soin suivent le joueur
            if proj.player then
                proj.x = proj.player.x
                proj.y = proj.player.y
            end
            
            proj.timer = proj.timer - dt
            proj.phase = 1 - (proj.timer / 0.5)
            
            if proj.timer <= 0 then
                table.remove(self.projectiles, i)
            else
                i = i + 1
            end
        elseif proj.isGrab then
            -- La saisie a plusieurs états
            if proj.state == "seeking" then
                -- Phase de recherche d'ennemi (très courte)
                proj.timer = proj.timer - dt
                if proj.timer <= 0 then
                    -- Passer à throwing (la recherche se fait dans checkProjectileCollisions)
                    if proj.grabbedEnemy then
                        proj.state = "throwing"
                    else
                        -- Pas d'ennemi trouvé, supprimer
                        table.remove(self.projectiles, i)
                    end
                else
                    i = i + 1
                end
                
            elseif proj.state == "throwing" then
                -- L'ennemi est projeté comme un projectile
                proj.x = proj.x + proj.dirX * proj.speed * dt
                proj.y = proj.y + proj.dirY * proj.speed * dt
                proj.distance = proj.distance + proj.speed * dt
                
                if proj.distance > proj.maxDistance then
                    -- Fin de la projection, remettre l'ennemi à sa position finale
                    if proj.grabbedEnemy then
                        proj.grabbedEnemy.relX = math.max(0.05, math.min(0.95, (proj.x - proj.roomX) / proj.roomWidth))
                        proj.grabbedEnemy.relY = math.max(0.05, math.min(0.95, (proj.y - proj.roomY) / proj.roomHeight))
                    end
                    table.remove(self.projectiles, i)
                else
                    -- Mettre à jour la position de l'ennemi saisi
                    if proj.grabbedEnemy then
                        proj.grabbedEnemy.relX = (proj.x - proj.roomX) / proj.roomWidth
                        proj.grabbedEnemy.relY = (proj.y - proj.roomY) / proj.roomHeight
                    end
                    i = i + 1
                end
            else
                i = i + 1
            end
        elseif proj.isproj then
            -- Les lances suivent leur timer
            proj.timer = proj.timer - dt
            
            -- Passer de warning à impact quand le timer atteint 0
            if proj.timer <= 0 and proj.state == "warning" then
                proj.state = "impact"
                proj.timer = 0.3  -- Durée de l'impact (pour l'animation)
            elseif proj.timer <= 0 and proj.state == "impact" then
                -- Supprimer la lance après l'impact
                table.remove(self.projectiles, i)
            else
                i = i + 1
            end
        elseif proj.isExplosion then
            -- Les explosions restent sur place
            proj.timer = proj.timer - dt
            proj.phase = 1 - (proj.timer / 0.4)  -- Phase de 0 à 1
            
            if proj.timer <= 0 then
                table.remove(self.projectiles, i)
            else
                i = i + 1
            end
        elseif proj.isAura then
            -- Les auras suivent le joueur
            if proj.player then
                proj.x = proj.player.x
                proj.y = proj.player.y
                
                -- Mettre à jour les timers de tick par ennemi
                for enemy, tickTimer in pairs(proj.enemyTickTimers) do
                    proj.enemyTickTimers[enemy] = tickTimer - dt
                end
            end
            
            -- Décrémenter le timer et supprimer si expiré
            proj.timer = proj.timer - dt
            if proj.timer <= 0 then
                table.remove(self.projectiles, i)
            else
                i = i + 1
            end
        elseif proj.isShield then
            -- Les boucliers suivent le joueur
            if proj.player then
                proj.x = proj.player.x
                proj.y = proj.player.y
            end
            
            -- Décrémenter le timer et supprimer si expiré
            proj.timer = proj.timer - dt
            if proj.timer <= 0 then
                table.remove(self.projectiles, i)
            else
                i = i + 1
            end
        elseif proj.isRay then
            if proj.player then
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
            
        else
            -- Projectiles normaux
            if proj.dirX and proj.dirY and proj.speed then
                proj.x = proj.x + proj.dirX * proj.speed * dt
                proj.y = proj.y + proj.dirY * proj.speed * dt
                proj.distance = proj.distance + proj.speed * dt
                
                if proj.distance > proj.maxDistance then
                    table.remove(self.projectiles, i)
                else
                    i = i + 1
                end
            else
                -- Projectile invalide
                table.remove(self.projectiles, i)
            end
        end
    end
end

function Pedro:checkProjectileCollisions(enemies)
    -- Traitement spécial pour la saisie en phase seeking
    for projIdx = #self.projectiles, 1, -1 do
        local proj = self.projectiles[projIdx]
        
        if proj.isGrab and proj.state == "seeking" then
            local closestEnemy = nil
            local closestDist = proj.grabRange
            
            for _, mob in ipairs(enemies) do
                if mob and (not mob.isDead or not mob:isDead()) and mob.state ~= "underground" then
                    local mobX = mob.relX * proj.roomWidth + proj.roomX
                    local mobY = mob.relY * proj.roomHeight + proj.roomY
                    
                    local dx = mobX - proj.player.x
                    local dy = mobY - proj.player.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    
                    if dist < closestDist then
                        closestDist = dist
                        closestEnemy = mob
                    end
                end
            end
            
            -- Si un ennemi a été trouvé, le saisir
            if closestEnemy then
                proj.grabbedEnemy = closestEnemy
                closestEnemy:takeDamage(proj.throwDamage or 30)
                proj.x = proj.roomX + closestEnemy.relX * proj.roomWidth
                proj.y = proj.roomY + closestEnemy.relY * proj.roomHeight
            end
        end
    end
    
    -- Boucle principale de collision
    for projIdx = #self.projectiles, 1, -1 do
        local proj = self.projectiles[projIdx]
        if not proj.hit then
            
            for mobIdx = #enemies, 1, -1 do
                local mob = enemies[mobIdx]
                if not mob then goto continue_mob end
                if mob.state == "underground" then goto continue_mob end
                if not mob.isDead or not mob:isDead() then
                    local mobX = mob.relX * proj.roomWidth + proj.roomX
                    local mobY = mob.relY * proj.roomHeight + proj.roomY
                    
                    local collides = false
                    
                    -- ═══ SECTION 1 : DÉTECTION DE COLLISION ═══
                    if proj.isRay then
                        local rayEndX = proj.x + proj.dirX * (proj.length or 400)
                        local rayEndY = proj.y + proj.dirY * (proj.length or 400)
                        local dx = rayEndX - proj.x
                        local dy = rayEndY - proj.y
                        local rayLen = math.sqrt(dx*dx + dy*dy)
                        
                        if rayLen > 0 then
                            local t = ((mobX - proj.x) * dx + (mobY - proj.y) * dy) / (rayLen * rayLen)
                            t = math.max(0, math.min(1, t))
                            local closestX = proj.x + t * dx
                            local closestY = proj.y + t * dy
                            local distX = mobX - closestX
                            local distY = mobY - closestY
                            local dist = math.sqrt(distX*distX + distY*distY)
                            
                            if dist < mob.size + (proj.width or 30) / 2 then
                                collides = true
                            end
                        end
                        
                    elseif proj.isExplosion then
                        local dx = proj.x - mobX
                        local dy = proj.y - mobY
                        local dist = math.sqrt(dx * dx + dy * dy)
                        
                        if dist < proj.radius then
                            collides = true
                        end
                        
                    elseif proj.isproj then
                        if proj.state == "impact" and not proj.hasHit then
                            local dx = proj.x - mobX
                            local dy = proj.y - mobY
                            local dist = math.sqrt(dx * dx + dy * dy)
                            
                            if dist < proj.radius then
                                collides = true
                            end
                        end
                        
                    elseif proj.isOrb then
                        local dx = proj.x - mobX
                        local dy = proj.y - mobY
                        local dist = math.sqrt(dx * dx + dy * dy)
                        
                        if dist < proj.radius + mob.size then
                            collides = true
                        end
                        
                    elseif proj.isShield then
                        local dx = proj.x - mobX
                        local dy = proj.y - mobY
                        local dist = math.sqrt(dx * dx + dy * dy)
                        
                        if dist < proj.radius then
                            collides = true
                        end
                        
                    elseif proj.isAura then
                        local dx = proj.x - mobX
                        local dy = proj.y - mobY
                        local dist = math.sqrt(dx * dx + dy * dy)
                        
                        if dist < proj.radius then
                            collides = true
                        end
                        
                    elseif proj.isGrab and proj.state == "throwing" then
                        if mob ~= proj.grabbedEnemy then
                            local dx = proj.x - mobX
                            local dy = proj.y - mobY
                            local dist = math.sqrt(dx * dx + dy * dy)
                            
                            local collisionRadius = ((proj.grabbedEnemy and proj.grabbedEnemy.size) or 20) + (mob.size or 20)
                            
                            if dist < collisionRadius then
                                collides = true
                            end
                        end
                        
                    else
                        -- Projectile normal
                        local projRadius = proj.radius or 5
                        local dx = proj.x - mobX
                        local dy = proj.y - mobY
                        local dist = math.sqrt(dx * dx + dy * dy)
                        
                        if dist < projRadius + mob.size then
                            collides = true
                        end
                    end
                    
                    -- ═══ SECTION 2 : APPLICATION DES EFFETS ═══
                    if collides then
                        if proj.isRay then
                            if not proj.hitEnemies[mob] then
                                if proj.onHit then
                                    proj:onHit(mob)
                                else
                                    mob:takeDamage(proj.damage or 10)
                                end
                                proj.hitEnemies[mob] = true
                            end
                            
                        elseif proj.isExplosion then
                            if not proj.hitEnemies[mob] then
                                if proj.onHit then
                                    proj:onHit(mob)
                                else
                                    mob:takeDamage(proj.damage or 25)
                                end
                                proj.hitEnemies[mob] = true
                            end
                            
                        elseif proj.isproj then
                            if not proj.hasHit then
                                if proj.onHit then
                                    proj:onHit(mob)
                                else
                                    mob:takeDamage(proj.damage or 35)
                                end
                                proj.hasHit = true
                            end
                            
                        elseif proj.isOrb then
                            if not proj.hitCooldowns[mob] or proj.hitCooldowns[mob] <= 0 then
                                if proj.onHit then
                                    proj:onHit(mob)
                                else
                                    mob:takeDamage(proj.damage or 10)
                                end
                                proj.hitCooldowns[mob] = 0.5
                            end
                            
                        elseif proj.isShield then
                            if not proj.hitEnemies[mob] then
                                if proj.onHit then
                                    proj:onHit(mob)
                                else
                                    mob:takeDamage(proj.damage or 20)
                                end
                                
                                -- Knockback
                                local dx = mobX - proj.x
                                local dy = mobY - proj.y
                                local dist = math.sqrt(dx*dx + dy*dy)
                                
                                if dist > 0 then
                                    local nx = dx / dist
                                    local ny = dy / dist
                                    local knockbackDistance = proj.knockbackForce or 300
                                    local newMobX = mobX + nx * knockbackDistance
                                    local newMobY = mobY + ny * knockbackDistance
                                    
                                    mob.relX = math.max(0.05, math.min(0.95, (newMobX - proj.roomX) / proj.roomWidth))
                                    mob.relY = math.max(0.05, math.min(0.95, (newMobY - proj.roomY) / proj.roomHeight))
                                end
                                
                                proj.hitEnemies[mob] = true
                            end
                            
                        elseif proj.isAura then
                            if not proj.enemyTickTimers[mob] or proj.enemyTickTimers[mob] <= 0 then
                                if proj.onHit then
                                    proj:onHit(mob)
                                else
                                    mob:takeDamage(proj.damage or 3)
                                end
                                proj.enemyTickTimers[mob] = proj.tickRate or 0.5
                            end
                            
                        elseif proj.isGrab and proj.state == "throwing" then
                            if not proj.hitEnemies[mob] and mob ~= proj.grabbedEnemy then
                                mob:takeDamage(proj.collisionDamage or 20)
                                proj.hitEnemies[mob] = true
                            end
                            
                        else
                            -- Projectile normal
                            if proj.onHit then
                                proj:onHit(mob)
                            else
                                mob:takeDamage(proj.damage or 10)
                            end
                            proj.hit = true
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
    for _, proj in ipairs(self.projectiles) do
        if proj.isRay then
            -- Rayon laser
            love.graphics.setColor(1, 0.3, 0.3, 0.8)
            love.graphics.setLineWidth(proj.width or 30)
            local endX = proj.x + proj.dirX * (proj.length or 400)
            local endY = proj.y + proj.dirY * (proj.length or 400)
            love.graphics.line(proj.x, proj.y, endX, endY)
            
            love.graphics.setColor(1, 1, 1, 0.6)
            love.graphics.setLineWidth((proj.width or 30) * 0.5)
            love.graphics.line(proj.x, proj.y, endX, endY)
        elseif proj.isHeal then
            -- Effet de soin visuel (croix verte + particules)
            local phase = proj.phase
            local alpha = 1 - phase
            
            -- Croix médicale verte qui pulse
            love.graphics.setColor(0.2, 1, 0.2, alpha * 0.9)
            love.graphics.setLineWidth(10)
            local crossSize = 25 + phase * 15
            love.graphics.line(proj.x - crossSize, proj.y, proj.x + crossSize, proj.y)
            love.graphics.line(proj.x, proj.y - crossSize, proj.x, proj.y + crossSize)
            
            -- Particules de soin qui montent
            love.graphics.setColor(0.5, 1, 0.5, alpha)
            for i = 1, 8 do
                local angle = (i / 8) * math.pi * 2
                local radius = 40 + phase * 30
                local py = proj.y - phase * 40  -- Monte vers le haut
                local px = proj.x + math.cos(angle) * radius * (1 - phase)
                love.graphics.circle("fill", px, py, 5 * (1 - phase))
            end
            
            -- Cercle de soin qui s'étend
            love.graphics.setColor(0.3, 1, 0.3, alpha * 0.4)
            love.graphics.circle("fill", proj.x, proj.y, 50 * phase)    
        elseif proj.isExplosion then
            -- Explosion avec effet de glitch digital
            local phase = proj.phase
            
            -- Cercle extérieur qui s'étend
            local expandRadius = proj.radius * (0.5 + phase * 0.8)
            local alpha = 1 - phase
            
            -- Effet de glitch : plusieurs cercles décalés
            for offset = -3, 3, 3 do
                love.graphics.setColor(0, 1, 0.5, alpha * 0.3)
                love.graphics.circle("fill", proj.x + offset, proj.y, expandRadius)
            end
            
            -- Cercle principal vert néon
            love.graphics.setColor(0, 1, 0.3, alpha * 0.6)
            love.graphics.circle("fill", proj.x, proj.y, expandRadius * 0.8)
            
            -- Flash blanc au centre
            love.graphics.setColor(1, 1, 1, alpha * 0.8)
            love.graphics.circle("fill", proj.x, proj.y, expandRadius * 0.3)
            
            -- Lignes de code qui s'échappent
            love.graphics.setColor(0, 1, 0.5, alpha)
            love.graphics.setLineWidth(2)
            for i = 1, 8 do
                local angle = (i / 8) * math.pi * 2 + phase * math.pi
                local length = expandRadius * (0.8 + math.random() * 0.4)
                local x1 = proj.x + math.cos(angle) * (expandRadius * 0.5)
                local y1 = proj.y + math.sin(angle) * (expandRadius * 0.5)
                local x2 = proj.x + math.cos(angle) * length
                local y2 = proj.y + math.sin(angle) * length
                love.graphics.line(x1, y1, x2, y2)
            end
            
            -- Contour qui pulse
            love.graphics.setColor(0, 0.8, 0.3, alpha * 0.8)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", proj.x, proj.y, expandRadius)
            
        elseif proj.isproj then
            if proj.state == "warning" then
                -- Cercle de prévision (pulse)
                local alpha = 0.3 + 0.4 * math.sin(love.timer.getTime() * 10)
                love.graphics.setColor(1, 0.8, 0, alpha)
                love.graphics.circle("fill", proj.x, proj.y, proj.radius)
                
                -- Contour rouge
                love.graphics.setColor(1, 0, 0, 0.8)
                love.graphics.setLineWidth(3)
                love.graphics.circle("line", proj.x, proj.y, proj.radius)
                
                -- Croix au centre
                love.graphics.setLineWidth(2)
                love.graphics.line(proj.x - 10, proj.y, proj.x + 10, proj.y)
                love.graphics.line(proj.x, proj.y - 10, proj.x, proj.y + 10)
                
            elseif proj.state == "impact" then
                -- Flash d'impact
                local flash = 1 - (proj.timer / 0.3)
                love.graphics.setColor(1, 1, 0.8, flash)
                love.graphics.circle("fill", proj.x, proj.y, proj.radius * (1 + flash * 0.5))
                
                -- Lance qui frappe
                love.graphics.setColor(0.8, 0.8, 0.9, flash)
                love.graphics.setLineWidth(8)
                love.graphics.line(proj.x, proj.y - proj.radius * 1.5, proj.x, proj.y)
            end
            
        elseif proj.isOrb then
            -- Orbes avec effet de lueur
            love.graphics.setColor(0.8, 0.6, 0.2, 0.3)
            love.graphics.circle("fill", proj.x, proj.y, proj.radius * 1.5)
            
            love.graphics.setColor(0.9, 0.7, 0.3, 0.9)
            love.graphics.circle("fill", proj.x, proj.y, proj.radius)
            
            love.graphics.setColor(1, 0.9, 0.6, 1)
            love.graphics.circle("fill", proj.x, proj.y, proj.radius * 0.5)
            
        elseif proj.isShield then
            -- Dessiner le bouclier avec effet de rotation et pulsation
            local time = love.timer.getTime()
            local pulse = 0.8 + 0.2 * math.sin(time * 5)
            
            -- Cercle externe (aura dorée)
            love.graphics.setColor(1, 0.9, 0.3, 0.2 * pulse)
            love.graphics.circle("fill", proj.x, proj.y, proj.radius * 1.2)
            
            -- Bouclier principal
            love.graphics.setColor(0.9, 0.9, 1, 0.4 * pulse)
            love.graphics.circle("fill", proj.x, proj.y, proj.radius)
            
            -- Dessiner 4 croix rotatives pour l'effet templier
            love.graphics.setColor(1, 0.95, 0.5, 0.8)
            love.graphics.setLineWidth(4)
            
            for i = 0, 3 do
                local angle = time * 2 + (i * math.pi / 2)
                local length = proj.radius * 0.8
                
                -- Bras de la croix
                local x1 = proj.x + math.cos(angle) * length * 0.3
                local y1 = proj.y + math.sin(angle) * length * 0.3
                local x2 = proj.x + math.cos(angle) * length
                local y2 = proj.y + math.sin(angle) * length
                
                love.graphics.line(x1, y1, x2, y2)
            end
            
            -- Contour du bouclier
            love.graphics.setColor(1, 1, 0.7, 0.6)
            love.graphics.setLineWidth(3)
            love.graphics.circle("line", proj.x, proj.y, proj.radius)
            
        elseif proj.isAura then
            -- Dessiner l'aura de poison avec effet pulsant
            local pulse = 0.7 + 0.3 * math.sin(love.timer.getTime() * 3)
            
            -- Cercle externe (nuage de poison)
            love.graphics.setColor(0.2, 0.6, 0.2, 0.15 * pulse)
            love.graphics.circle("fill", proj.x, proj.y, proj.radius * 1.2)
            
            -- Cercle principal
            love.graphics.setColor(0.3, 0.7, 0.3, 0.25 * pulse)
            love.graphics.circle("fill", proj.x, proj.y, proj.radius)
            
            -- Cercle interne (plus intense)
            love.graphics.setColor(0.4, 0.8, 0.3, 0.35 * pulse)
            love.graphics.circle("fill", proj.x, proj.y, proj.radius * 0.7)
            
            -- Contour de l'aura (pour visualiser le rayon)
            love.graphics.setColor(0.5, 0.9, 0.4, 0.4)
            love.graphics.setLineWidth(2)
            love.graphics.circle("line", proj.x, proj.y, proj.radius)
            
        elseif proj.isGrab then
            if proj.state == "seeking" then
                local pulse = 0.7 + 0.3 * math.sin(love.timer.getTime() * 10)
                love.graphics.setColor(1, 0.8, 0.2, 0.4 * pulse)
                love.graphics.circle("fill", proj.player.x, proj.player.y, proj.grabRange)
                
                love.graphics.setColor(1, 0.6, 0, 0.8)
                love.graphics.setLineWidth(3)
                love.graphics.circle("line", proj.player.x, proj.player.y, proj.grabRange * pulse)
                
            elseif proj.state == "throwing" and proj.grabbedEnemy then
                love.graphics.setColor(1, 0.8, 0.2, 0.6)
                love.graphics.setLineWidth(8)
                
                local trailLength = 50
                local trailX = proj.x - proj.dirX * trailLength
                local trailY = proj.y - proj.dirY * trailLength
                love.graphics.line(trailX, trailY, proj.x, proj.y)
                
                -- Étoiles autour de l'ennemi
                for i = 1, 4 do
                    local angle = love.timer.getTime() * 5 + (i * math.pi / 2)
                    local radius = 30
                    local sx = proj.x + math.cos(angle) * radius
                    local sy = proj.y + math.sin(angle) * radius
                    love.graphics.circle("fill", sx, sy, 3)
                end
            end
            
        elseif proj.draw then
            proj:draw()
            
        else
            -- Projectile normal
            if proj.color then
                love.graphics.setColor(proj.color[1], proj.color[2], proj.color[3])
            else
                love.graphics.setColor(1, 0, 0)
            end
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

        -- scaleX négatif si on regarde à gauche
        local scaleX = (self.hitboxRadiusX * 2) / imgWidth
        if self.facing == "left" then
            scaleX = -scaleX
        end
        local scaleY = (self.hitboxRadiusY * 2) / imgHeight

        love.graphics.draw(
            img,
            self.x,
            self.y,
            0,          -- rotation
            scaleX,
            scaleY,
            imgWidth/2,
            imgHeight/2
        )
    end
    
    -- Dessiner les projectiles
    self:drawProjectiles()

    -- Barre de vie du joueur (en bas à droite)
    if self.maxHp and self.hp then
        local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
        local width = 200 * scale
        local height = 15 * scale
        local margin = 20 * scale

        local x0 = _G.gameConfig.windowWidth - width - margin - 50
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

-- Équiper un masque dans un slot précis (1 ou 2)
function Pedro:equipMask(mask, slot)
    self.maskManager:equip(mask, slot)
    if mask and mask.onEquip then
        mask:onEquip(self)
    end
end

-- Déséquiper
function Pedro:unequipMask(slot)
    local mask = self.maskManager:getSlot(slot)
    if mask and mask.onUnequip then
        mask:onUnequip(self)
    end
    self.maskManager:unequip(slot)
end



function Pedro:getMaskDamageBonus()
    -- Retourner les dégâts bonus du mask équipé
    if self.equippedMask and self.equippedMask.getDamageBonus then
        return self.equippedMask:getLifeBonus()
    end
    return 0
end

return Pedro