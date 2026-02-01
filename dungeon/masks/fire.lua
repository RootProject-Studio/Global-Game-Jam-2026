local Mask = require("dungeon.masks.mask")
local Fire = setmetatable({}, {__index = Mask})
Fire.__index = Fire

function Fire:new()
    local obj = setmetatable({}, self)
    obj.name = "Fire"
    obj.attackType = "distance"
    obj.damage = 2  -- Dégâts par projectile (3 projectiles = 24 dégâts total si tous touchent)
    
    -- Propriétés du tir en éventail
    obj.projectileCount = 20      -- Nombre de projectiles par tir
    obj.spreadAngle = math.pi / 6  -- 30° d'écart total (15° de chaque côté)
    obj.projectileSpeed = 50    -- Vitesse des projectiles
    obj.projectileRange = 200    -- Portée maximale
    obj.projectileSize = 8       -- Taille visuelle
    
    obj.shootCooldown = 1.0      -- Cooldown court
    obj.shootTimer = 0
    
    return obj
end

function Fire:update(dt, player)
    -- Mettre à jour le cooldown de tir
    if self.shootTimer > 0 then
        self.shootTimer = self.shootTimer - dt
    end
end

function Fire:draw(ctx)
    love.graphics.setColor(0.2, 0.6, 0.3)
    love.graphics.circle("fill", x, y, self.size * (ctx.scale or 1))
end

function Fire:onEquip(player)
    if not player.projectiles then
        player.projectiles = {}
    end
    if not player.equippedMask then
        player.equippedMask = self
    end
end

function Fire:onUnequip(player)
    -- Nettoyer les projectiles si on déséquipe
    if player.projectiles then
        for i = #player.projectiles, 1, -1 do
            if player.projectiles[i].type == "Fire_shot" then
                table.remove(player.projectiles, i)
            end
        end
    end
end

function Fire:canShoot()
    return self.shootTimer <= 0
end

function Fire:shoot(player, dirX, dirY, roomContext)
    -- Vérifier si on peut tirer
    if not self:canShoot() then
        return false
    end
    
    if not roomContext then
        return false
    end
    
    -- Calculer l'angle de base de la direction
    local baseAngle = math.atan2(dirY, dirX)
    
    -- Créer les projectiles en éventail
    for i = 1, self.projectileCount do
        -- Calculer l'angle pour ce projectile
        -- Centrer l'éventail : le projectile du milieu va droit, les autres sont décalés
        local offset = math.random(self.projectileCount) / 2
        local angle = baseAngle + (offset * self.spreadAngle / (self.projectileCount - 1))
        
        -- Position de départ légèrement décalée du joueur
        local startOffset = 20
        local startX = player.x + math.cos(angle) * startOffset
        local startY = player.y + math.sin(angle) * startOffset
        
        local projectile = {
            x = startX,
            y = startY,
            dirX = math.cos(angle),
            dirY = math.sin(angle),
            speed = self.projectileSpeed,
            distance = 0,
            maxDistance = self.projectileRange,
            radius = self.projectileSize,
            damage = self.damage,
            
            -- Métadonnées
            roomX = roomContext.roomX,
            roomY = roomContext.roomY,
            roomWidth = roomContext.roomWidth,
            roomHeight = roomContext.roomHeight,
            type = "Fire_shot",
            
            -- Propriété visuelle pour distinguer les projectiles Fire
            color = {1, 0, 0}  -- Vert
        }
        
        player:addProjectile(projectile)
    end
    
    -- Réinitialiser le cooldown
    self.shootTimer = self.shootCooldown
    
    return true
end

function Fire:effect()
end

return Fire
