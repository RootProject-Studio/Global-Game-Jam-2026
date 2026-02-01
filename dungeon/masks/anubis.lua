local Mask = require("dungeon.masks.mask")
local Anubis = setmetatable({}, {__index = Mask})
Anubis.__index = Anubis

function Anubis:new()
    local obj = setmetatable({}, self)
    obj.name = "Anubis"
    obj.attackType = "orbital"
    obj.damage = 15  -- Dégâts par orbe
    
    -- Propriétés des orbes
    obj.orbCount = 3           -- Nombre d'orbes
    obj.orbitRadius = 80       -- Rayon de l'orbite autour du joueur
    obj.orbitSpeed = 2         -- Vitesse de rotation (radians/sec)
    obj.orbDuration = 5.0      -- Durée de vie des orbes (secondes)
    obj.orbRadius = 10         -- Taille visuelle de chaque orbe
    
    obj.shootCooldown = 8.0    -- Cooldown entre deux invocations
    obj.shootTimer = 0
    
    return obj
end

function Anubis:update(dt, player)
    -- Mettre à jour le cooldown de tir
    if self.shootTimer > 0 then
        self.shootTimer = self.shootTimer - dt
    end
end

function Anubis:draw(ctx)
    love.graphics.setColor(0.8, 0.6, 0.2)
    love.graphics.circle("fill", x, y, self.size * (ctx.scale or 1))
end

function Anubis:onEquip(player)
    if not player.projectiles then
        player.projectiles = {}
    end
    if not player.equippedMask then
        player.equippedMask = self
    end
end

function Anubis:onUnequip(player)
    -- Nettoyer les orbes si on déséquipe
    if player.projectiles then
        for i = #player.projectiles, 1, -1 do
            if player.projectiles[i].type == "orb" then
                table.remove(player.projectiles, i)
            end
        end
    end
end

function Anubis:canShoot()
    return self.shootTimer <= 0
end

function Anubis:shoot(player, dirX, dirY, roomContext)
    -- Vérifier si on peut tirer
    if not self:canShoot() then
        return false
    end
    
    if not roomContext then
        return false
    end
    
    -- Créer les orbes orbitaux
    for i = 1, self.orbCount do
        -- Angle initial réparti uniformément
        local angleOffset = (i - 1) * (math.pi * 2 / self.orbCount)
        
        local orb = {
            -- Position initiale (sera mise à jour dans update)
            x = player.x,
            y = player.y,
            
            -- Propriétés orbitales
            angle = angleOffset,           -- Angle actuel dans l'orbite
            orbitRadius = self.orbitRadius,
            orbitSpeed = self.orbitSpeed,
            
            -- Propriétés du projectile
            radius = self.orbRadius,
            damage = self.damage,
            timer = self.orbDuration,
            
            -- Métadonnées
            roomX = roomContext.roomX,
            roomY = roomContext.roomY,
            roomWidth = roomContext.roomWidth,
            roomHeight = roomContext.roomHeight,
            type = "orb",
            isOrb = true,
            player = player,  -- Référence au joueur pour orbiter autour de lui
            hitEnemies = {},  -- Tracker pour éviter les dégâts multiples rapides
            hitCooldowns = {} -- Cooldown par ennemi pour permettre multi-hit
        }
        
        player:addProjectile(orb)
    end
    
    -- Réinitialiser le cooldown
    self.shootTimer = self.shootCooldown
    
    return true
end

function Anubis:effect()
end

return Anubis