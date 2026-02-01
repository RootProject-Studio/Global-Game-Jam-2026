local Mask = require("dungeon.masks.mask")
local Hydra = setmetatable({}, {__index = Mask})
Hydra.__index = Hydra

function Hydra:new()
    local obj = setmetatable({}, self)
    obj.name = "Hydra"
    obj.attackType = "shotgun"
    obj.damage = 8  -- Dégâts par projectile (3 projectiles = 24 dégâts total si tous touchent)
    
    -- Propriétés du tir en éventail
    obj.projectileCount = 3      -- Nombre de projectiles par tir
    obj.spreadAngle = math.pi / 6  -- 30° d'écart total (15° de chaque côté)
    obj.projectileSpeed = 500    -- Vitesse des projectiles
    obj.projectileRange = 300    -- Portée maximale
    obj.projectileSize = 8       -- Taille visuelle
    
    obj.shootCooldown = 1.0      -- Cooldown court
    obj.shootTimer = 0
    
    return obj
end

function Hydra:update(dt, player)
    -- Mettre à jour le cooldown de tir
    if self.shootTimer > 0 then
        self.shootTimer = self.shootTimer - dt
    end
end

function Hydra:draw(ctx)
    love.graphics.setColor(0.2, 0.6, 0.3)
    love.graphics.circle("fill", x, y, self.size * (ctx.scale or 1))
end

function Hydra:onEquip(player)
    if not player.projectiles then
        player.projectiles = {}
    end
    if not player.equippedMask then
        player.equippedMask = self
    end
end

function Hydra:onUnequip(player)
    -- Nettoyer les projectiles si on déséquipe
    if player.projectiles then
        for i = #player.projectiles, 1, -1 do
            if player.projectiles[i].type == "hydra_shot" then
                table.remove(player.projectiles, i)
            end
        end
    end
end

function Hydra:canShoot()
    return self.shootTimer <= 0
end

function Hydra:shoot(player, dirX, dirY, roomContext)
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
        local offset = (i - 1) - (self.projectileCount - 1) / 2
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
            type = "hydra_shot",
            
            -- Propriété visuelle pour distinguer les projectiles Hydra
            color = {0.2, 0.8, 0.4}  -- Vert
        }
        
        player:addProjectile(projectile)
    end
    
    -- Réinitialiser le cooldown
    self.shootTimer = self.shootCooldown
    
    return true
end

function Hydra:effect()
end

function Hydra:getInfo()
    return {
        name = self.name,
        attackType = self.attackType,
        damage = self.damage,
        projectileCount = self.projectileCount,
        spreadAngle = self.spreadAngle,
        projectileSpeed = self.projectileSpeed,
        projectileRange = self.projectileRange,
        projectileSize = self.projectileSize,
        shootCooldown = self.shootCooldown,

        imagePath = "dungeon/masks/assets/hydra.png",  -- chemin vers l'image du masque
        description = "Tire plusieurs projectiles en éventail pour toucher plusieurs ennemis à la fois" -- courte description
    }
end


return Hydra