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
    if not self:canShoot() then return false end
    if not roomContext then return false end

    local eyeOffsetDistance = 20
    local eyeX = player.x + dirX * eyeOffsetDistance
    local eyeY = player.y + dirY * eyeOffsetDistance

    -- Pour un tir corps à corps : distance courte mais adaptable à la salle
    local baseDistance = 50  -- distance de base du petit coup
    local scaleFactor = math.min(roomContext.roomWidth, roomContext.roomHeight) / 800
    local maxDistance = baseDistance * scaleFactor  -- plus grande salle → petit peu plus loin

    local proj = {
        x = eyeX,
        y = eyeY,
        dirX = dirX,
        dirY = dirY,
        speed = 300,           -- vitesse faible, juste pour “atteindre le voisin”
        distance = 0,
        maxDistance = maxDistance,
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

    player:addProjectile(proj)

    self.shootTimer = self.shootCooldown
    self.rayActive = true
    self.rayTimer = self.rayDuration

    return true
end


function Scream:effect()
end

function Scream:getInfo()
    return {
        name = self.name,
        attackType = self.attackType,
        damage = self.damage,
        rayLength = self.rayLength,
        rayWidth = self.rayWidth,
        shootCooldown = self.shootCooldown,
        rayDuration = self.rayDuration,
        rayActive = self.rayActive,

        imagePath = "dungeon/masks/assets/scream.png",  -- chemin vers l'image du masque
        description = "Un masque qui te permet de donner des petit coup de couteau droit dans tes ennemis." -- courte description

    }
end


return Scream