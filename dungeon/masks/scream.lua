local Mask = require("dungeon.masks.mask")
local ConfigLoader = require("dungeon.masks.config_loader")
local Scream = setmetatable({}, {__index = Mask})
Scream.__index = Scream

function Scream:new()
    local obj = setmetatable({}, self)

    local config = ConfigLoader.getMaskConfig("Scream")

    obj.name = config.name
    obj.attackType = config.attackType -- La distance sera très courte
    obj.damage = config.damage

    obj.rayLength = config.rayLength
    obj.rayWidth = config.rayWidth
    obj.shootCooldown = config.shootCooldown
    obj.shootTimer = 0
    obj.rayDuration = config.rayDuration
    obj.rayActive = false
    obj.rayTimer = 0

    return obj
end

function Scream:update(dt, player)
    if self.shootTimer > 0 then
        self.shootTimer = self.shootTimer - dt
    end
end

function Scream:draw(ctx)
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.circle("fill", x, y, self.size * (ctx.scale or 1))
end

function Scream:onEquip(player)
    if not player.projectiles then
        player.projectiles = {}
    end
    if not player.equippedMask then
        player.equippedMask = self
    end
end

function Scream:onUnequip(player)
    -- Nettoyer les projectiles si on déséquipe
    if player.projectiles then
        player.projectiles = {}
    end
end

function Scream:canShoot()
    -- Vérifier si on peut tirer
    return self.shootTimer <= 0
end


function Scream:shoot(player, dirX, dirY, roomContext)
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
    local proj = {
        x = eyeX,
        y = eyeY,
        dirX = dirX,
        dirY = dirY,
        speed = 600,            -- vitesse de déplacement
        distance = 0,           -- distance parcourue (commence à 0)
        maxDistance = self.rayLength,  -- disparaît après rayLength pixels
        radius = self.rayWidth,
        damage = 10 + self.damage,
        roomX = roomContext.roomX,
        roomY = roomContext.roomY,
        roomWidth = roomContext.roomWidth,
        roomHeight = roomContext.roomHeight,
        type = "couteau",
        hitEnemies = {},
        player = player
    }
    
    -- Ajouter le rayon via la méthode générique
    player:addProjectile(proj)
    
    -- Réinitialiser le cooldown avec un gros délai
    self.shootTimer = self.shootCooldown
    
    -- Activer le rayon visible
    self.rayActive = true
    self.rayTimer = self.rayDuration
    
    return true
end

function Scream:effect()
end

return Scream