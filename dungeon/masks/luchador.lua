local Mask = require("dungeon.masks.mask")
local Luchador = setmetatable({}, {__index = Mask})
Luchador.__index = Luchador

function Luchador:new()
    local obj = setmetatable({}, self)
    obj.name = "Luchador"
    obj.attackType = "grapple"
    obj.damage = 30  -- Dégâts de la projection
    
    -- Propriétés de la saisie
    obj.grabRange = 100          -- Rayon de saisie
    obj.throwDistance = 200      -- Distance de projection
    obj.throwDamage = 30         -- Dégâts à l'ennemi projeté
    obj.collisionDamage = 20     -- Dégâts aux ennemis percutés
    obj.projectileSpeed = 800    -- Vitesse de l'ennemi projeté
    
    obj.shootCooldown = 3.0      -- Cooldown moyen
    obj.shootTimer = 0
    
    return obj
end

function Luchador:update(dt, player)
    -- Mettre à jour le cooldown de tir
    if self.shootTimer > 0 then
        self.shootTimer = self.shootTimer - dt
    end
end

function Luchador:draw(ctx)
    love.graphics.setColor(1, 0.8, 0.2)
    love.graphics.circle("fill", x, y, self.size * (ctx.scale or 1))
end

function Luchador:onEquip(player)
    if not player.projectiles then
        player.projectiles = {}
    end
    if not player.equippedMask then
        player.equippedMask = self
    end
end

function Luchador:onUnequip(player)
    -- Nettoyer les ennemis projetés si on déséquipe
    if player.projectiles then
        for i = #player.projectiles, 1, -1 do
            if player.projectiles[i].type == "thrown_enemy" then
                table.remove(player.projectiles, i)
            end
        end
    end
end

function Luchador:canShoot()
    return self.shootTimer <= 0
end

function Luchador:shoot(player, dirX, dirY, roomContext)
    -- Vérifier si on peut utiliser la saisie
    if not self:canShoot() then
        return false
    end
    
    if not roomContext then
        return false
    end
    
    -- Chercher l'ennemi le plus proche dans le rayon de saisie
    local closestEnemy = nil
    local closestDist = self.grabRange
    
    -- Accéder aux ennemis de la salle actuelle
    -- Note: On devra passer les ennemis via roomContext ou une autre méthode
    -- Pour l'instant, on va créer un "projectile" qui va chercher l'ennemi
    
    -- Créer un projectile de saisie qui va attirer puis projeter l'ennemi le plus proche
    local grab = {
        x = player.x,
        y = player.y,
        dirX = dirX,
        dirY = dirY,
        
        -- État de la saisie
        state = "seeking",  -- seeking → grabbing → throwing
        timer = 0.1,        -- Timer pour chercher l'ennemi
        
        -- Propriétés
        grabRange = self.grabRange,
        throwDistance = self.throwDistance,
        throwDamage = self.throwDamage,
        collisionDamage = self.collisionDamage,
        speed = self.projectileSpeed,
        
        -- Métadonnées
        roomX = roomContext.roomX,
        roomY = roomContext.roomY,
        roomWidth = roomContext.roomWidth,
        roomHeight = roomContext.roomHeight,
        type = "luchador_grab",
        isGrab = true,
        player = player,
        
        -- Ennemi saisi
        grabbedEnemy = nil,
        
        -- Pour la projection
        distance = 0,
        maxDistance = self.throwDistance,
        hitEnemies = {}  -- Ennemis percutés pendant la projection
    }
    
    player:addProjectile(grab)
    
    -- Réinitialiser le cooldown
    self.shootTimer = self.shootCooldown
    
    return true
end

function Luchador:effect()
end

function Luchador:getInfo()
    return {
        name = self.name,
        attackType = self.attackType,
        damage = self.damage,
        grabRange = self.grabRange,
        throwDistance = self.throwDistance,
        throwDamage = self.throwDamage,
        collisionDamage = self.collisionDamage,
        projectileSpeed = self.projectileSpeed,
        shootCooldown = self.shootCooldown,

        imagePath = "dungeon/masks/assets/luchador.png",  -- chemin vers l'image du masque
        description = "Saisit un ennemi proche et le projette pour infliger des dégâts aux ennemis percutés" -- courte description
    }
end


return Luchador