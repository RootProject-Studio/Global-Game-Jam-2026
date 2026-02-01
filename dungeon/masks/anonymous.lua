local Mask = require("dungeon.masks.mask")
local Anonymous = setmetatable({}, {__index = Mask})
Anonymous.__index = Anonymous

function Anonymous:new()
    local obj = setmetatable({}, self)
    obj.name = "Anonymous"
    obj.attackType = "glitch"
    obj.damage = 25  -- Dégâts par explosion
    
    -- Propriétés du glitch
    obj.explosionRadius = 80     -- Rayon des explosions
    obj.invincibilityDuration = 0.5  -- Invincibilité pendant le glitch
    obj.explosionDuration = 0.4  -- Durée de l'effet visuel d'explosion
    
    obj.shootCooldown = 5.0      -- Cooldown moyen
    obj.shootTimer = 0
    
    return obj
end

function Anonymous:update(dt, player)
    -- Mettre à jour le cooldown de tir
    if self.shootTimer > 0 then
        self.shootTimer = self.shootTimer - dt
    end
end

function Anonymous:draw(ctx)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.circle("fill", x, y, self.size * (ctx.scale or 1))
end

function Anonymous:onEquip(player)
    if not player.projectiles then
        player.projectiles = {}
    end
    if not player.equippedMask then
        player.equippedMask = self
    end
end

function Anonymous:onUnequip(player)
    -- Nettoyer les explosions si on déséquipe
    if player.projectiles then
        for i = #player.projectiles, 1, -1 do
            if player.projectiles[i].type == "glitch_explosion" then
                table.remove(player.projectiles, i)
            end
        end
    end
end

function Anonymous:canShoot()
    return self.shootTimer <= 0
end

function Anonymous:shoot(player, dirX, dirY, roomContext)
    -- Vérifier si on peut glitch
    if not self:canShoot() then
        return false
    end
    
    if not roomContext then
        return false
    end
    
    -- Sauvegarder l'ancienne position
    local oldX = player.x
    local oldY = player.y
    
    -- Calculer une nouvelle position aléatoire dans la salle
    -- Garder des marges pour ne pas spawn dans un mur
    local margin = 60
    local minX = roomContext.roomX + margin
    local maxX = roomContext.roomX + roomContext.roomWidth - margin
    local minY = roomContext.roomY + margin
    local maxY = roomContext.roomY + roomContext.roomHeight - margin
    
    local newX = minX + math.random() * (maxX - minX)
    local newY = minY + math.random() * (maxY - minY)
    
    -- Téléporter le joueur
    player.x = newX
    player.y = newY
    
    -- Donner l'invincibilité pendant le glitch
    player.hitCooldown = self.invincibilityDuration
    
    -- Créer une explosion à l'ancienne position
    local explosion1 = {
        x = oldX,
        y = oldY,
        radius = self.explosionRadius,
        damage = self.damage,
        timer = self.explosionDuration,
        
        -- Métadonnées
        roomX = roomContext.roomX,
        roomY = roomContext.roomY,
        roomWidth = roomContext.roomWidth,
        roomHeight = roomContext.roomHeight,
        type = "glitch_explosion",
        isExplosion = true,
        
        -- Tracker pour éviter les dégâts multiples
        hitEnemies = {},
        
        -- Effet visuel
        phase = 0  -- Pour l'animation (0 = début, 1 = fin)
    }
    
    -- Créer une explosion à la nouvelle position
    local explosion2 = {
        x = newX,
        y = newY,
        radius = self.explosionRadius,
        damage = self.damage,
        timer = self.explosionDuration,
        
        roomX = roomContext.roomX,
        roomY = roomContext.roomY,
        roomWidth = roomContext.roomWidth,
        roomHeight = roomContext.roomHeight,
        type = "glitch_explosion",
        isExplosion = true,
        
        hitEnemies = {},
        phase = 0
    }
    
    player:addProjectile(explosion1)
    player:addProjectile(explosion2)
    
    -- Réinitialiser le cooldown
    self.shootTimer = self.shootCooldown
    
    return true
end

function Anonymous:effect()
end

function Anonymous:getInfo()
    return {
        name = self.name,
        attackType = self.attackType,
        damage = self.damage,
        explosionRadius = self.explosionRadius,
        invincibilityDuration = self.invincibilityDuration,
        explosionDuration = self.explosionDuration,
        shootCooldown = self.shootCooldown,

        imagePath = "dungeon/masks/assets/anonymous.png",  -- chemin vers l'image du masque
        description = "Se téléporte en laissant des explosions et devient invincible pendant un court instant" -- courte description
    }
end


return Anonymous