local Mask = require("dungeon.masks.mask")
local Magrit = setmetatable({}, {__index = Mask})
Magrit.__index = Magrit

function Magrit:new()
    local obj = setmetatable({}, self)
    obj.name = "Magrit"
    obj.attackType = "aerial"
    obj.damage = 80  -- Gros dégâts par projectil
    
    -- Propriétés des projectils
    obj.projCount = 10           -- Nombre de projectils par invocation
    obj.warningDuration = 0.8    -- Durée du cercle de prévision (secondes)
    obj.impactRadius = 40        -- Rayon de la zone d'impact
    obj.projDelay = 0.15        -- Délai entre chaque projectil
    
    obj.shootCooldown = 6.0      -- Long cooldown
    obj.shootTimer = 0
    
    return obj
end

function Magrit:update(dt, player)
    -- Mettre à jour le cooldown de tir
    if self.shootTimer > 0 then
        self.shootTimer = self.shootTimer - dt
    end
end

function Magrit:draw(ctx)
    love.graphics.setColor(0.9, 0.9, 0.3)
    love.graphics.circle("fill", x, y, self.size * (ctx.scale or 1))
end

function Magrit:onEquip(player)
    if not player.projectiles then
        player.projectiles = {}
    end
    if not player.equippedMask then
        player.equippedMask = self
    end
end

function Magrit:onUnequip(player)
    -- Nettoyer les projectils si on déséquipe
    if player.projectiles then
        for i = #player.projectiles, 1, -1 do
            if player.projectiles[i].type == "Magrit_proj" then
                table.remove(player.projectiles, i)
            end
        end
    end
end

function Magrit:canShoot()
    return self.shootTimer <= 0
end

function Magrit:shoot(player, dirX, dirY, roomContext)
    -- Vérifier si on peut tirer
    if not self:canShoot() then
        return false
    end
    
    if not roomContext then
        return false
    end
    
    -- Créer plusieurs projectils à des positions aléatoires
    for i = 1, self.projCount do
        -- Position aléatoire dans la salle (en coordonnées relatives)
        local relX = 0.1 + math.random() * 0.8  -- Entre 10% et 90% de la largeur
        local relY = 0.1 + math.random() * 0.8  -- Entre 10% et 90% de la hauteur
        
        -- Convertir en position absolue
        local targetX = roomContext.roomX + relX * roomContext.roomWidth
        local targetY = roomContext.roomY + relY * roomContext.roomHeight
        
        local proj = {
            x = targetX,
            y = targetY,
            relX = relX,
            relY = relY,
            
            -- État de la projectil
            state = "warning",  -- warning → impact
            timer = self.warningDuration + (i - 1) * self.projDelay,  -- Délai progressif
            warningDuration = self.warningDuration,
            
            -- Propriétés
            radius = self.impactRadius,
            damage = self.damage,
            
            -- Métadonnées
            roomX = roomContext.roomX,
            roomY = roomContext.roomY,
            roomWidth = roomContext.roomWidth,
            roomHeight = roomContext.roomHeight,
            type = "Magrit_proj",
            isproj = true,
            
            -- Tracker pour éviter les dégâts multiples
            hasHit = false
        }
        
        player:addProjectile(proj)
    end
    
    -- Réinitialiser le cooldown
    self.shootTimer = self.shootCooldown
    
    return true
end

function Magrit:effect()
end

return Magrit