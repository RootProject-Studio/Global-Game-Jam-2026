local Mask = require("dungeon.masks.mask")
local Cyclope = setmetatable({}, {__index = Mask})
Cyclope.__index = Cyclope

function Cyclope:new()
    local obj = setmetatable({}, self)
    obj.name = "Cyclope"
    obj.attackType = "distance"
    obj.damage = 50  -- Dégâts bonus apportés par Cyclope
    obj.cooldown = 15
    obj.damageMultiplier = 1.5  -- Multiplicateur de dégâts (50% bonus)
    
    -- Propriétés du rayon laser
    obj.rayLength = 400  -- Longueur du rayon
    obj.rayWidth = 30    -- Largeur du rayon (épaisseur)
    obj.shootCooldown = 2.5  -- Gros cooldown (2.5 secondes)
    obj.shootTimer = 0
    obj.rayDuration = 0.5  -- Durée du rayon visible (en secondes) - augmenté pour être bien visible
    obj.rayActive = false
    obj.rayTimer = 0
    
    return obj
end

function Cyclope:update(dt, player)
    -- Mettre à jour le cooldown de tir
    if self.shootTimer > 0 then
        self.shootTimer = self.shootTimer - dt
    end
end

function Cyclope:draw(ctx)
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.circle("fill", x, y, self.size * (ctx.scale or 1))
end

function Cyclope:onEquip(player)
    player.hitCooldown = self.cooldown
    -- Initialiser les propriétés de projectiles dans le joueur
    if not player.projectiles then
        player.projectiles = {}
    end
    if not player.equippedMask then
        player.equippedMask = self
    end
end

function Cyclope:onUnequip(player)
    -- Nettoyer les projectiles si on déséquipe
    if player.projectiles then
        player.projectiles = {}
    end
end

function Cyclope:canShoot()
    -- Vérifier si on peut tirer
    return self.shootTimer <= 0
end

function Cyclope:shoot(player, dirX, dirY, roomContext)
    -- Vérifier si on peut tirer
    if not self:canShoot() then
        return false
    end
    
    -- Vérifier que le contexte de la salle est valide
    if not roomContext then
        return false
    end
    
    -- Calculer la position des yeux (offset depuis le centre selon la direction)
    -- Les yeux sont décalés de 20 pixels dans la direction du tir
    local eyeOffsetDistance = 20
    local eyeX = player.x + dirX * eyeOffsetDistance
    local eyeY = player.y + dirY * eyeOffsetDistance
    
    -- Créer un rayon laser immédiat (pas de projectile qui se déplace)
    local ray = {
        x = eyeX,
        y = eyeY,
        dirX = dirX,
        dirY = dirY,
        length = self.rayLength,
        width = self.rayWidth,
        radius = self.rayWidth / 2,  -- Rayon de collision basé sur la largeur
        damage = 10 + self.damage,  -- 10 dégâts de base + bonus du mask
        roomX = roomContext.roomX,
        roomY = roomContext.roomY,
        roomWidth = roomContext.roomWidth,
        roomHeight = roomContext.roomHeight,
        type = "ray",  -- Identifiant du type de projectile
        isRay = true,  -- Marquer que c'est un rayon
        timer = self.rayDuration,  -- Initialiser la durée du rayon
        hitEnemies = {},  -- Tracker les ennemis déjà touchés pour éviter les dégâts multiples
        player = player  -- Référence au joueur pour que le rayon le suive
    }
    
    -- Ajouter le rayon via la méthode générique
    player:addProjectile(ray)
    
    -- Réinitialiser le cooldown avec un gros délai
    self.shootTimer = self.shootCooldown
    
    -- Activer le rayon visible
    self.rayActive = true
    self.rayTimer = self.rayDuration
    
    return true
end

function Cyclope:effect()
end

return Cyclope