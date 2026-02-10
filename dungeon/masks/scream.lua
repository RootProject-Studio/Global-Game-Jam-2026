local Mask = require("dungeon.masks.mask")
local ConfigLoader = require("dungeon.masks.config_loader")
local Scream = setmetatable({}, {__index = Mask})
Scream.__index = Scream

-- Charger l'image du couteau une seule fois
local knifeImage = love.graphics.newImage("dungeon/masks/assets/couteau.png")

function Scream:new()
    local obj = setmetatable({}, self)
    local config = ConfigLoader.getMaskConfig("Scream")

    obj.name = config.name
    obj.attackType = config.attackType
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

function Scream:draw(ctx, player)
    if not player.projectiles then return end

    for _, proj in ipairs(player.projectiles) do
        if proj.type == "couteau" and proj.image then
            local angle = math.atan2(proj.dirY, proj.dirX)
            local scale = proj.maxDistance / math.max(proj.image:getWidth(), proj.image:getHeight())  -- optionnel
            love.graphics.setColor(1,1,1)
            love.graphics.draw(proj.image, proj.x, proj.y, angle, 1, 1, proj.image:getWidth()/2, proj.image:getHeight()/2)
        end
    end
end

function Scream:onEquip(player)
    if not player.projectiles then player.projectiles = {} end
    if not player.equippedMask then player.equippedMask = self end
end

function Scream:onUnequip(player)
    if player.projectiles then player.projectiles = {} end
end

function Scream:canShoot()
    return self.shootTimer <= 0
end

function Scream:shoot(player, dirX, dirY, roomContext)
    if not self:canShoot() then return false end
    if not roomContext then return false end

    local eyeOffsetDistance = 20
    local eyeX = player.x + dirX * eyeOffsetDistance
    local eyeY = player.y + dirY * eyeOffsetDistance

    -- Distance courte corps à corps, adaptée à la salle
    local baseDistance = 110
    local scaleFactor = math.min(roomContext.roomWidth, roomContext.roomHeight) / 800
    local maxDistance = baseDistance * scaleFactor

    -- Charger l'image du projectile (couteau)
    local knifeImage = love.graphics.newImage("dungeon/masks/assets/couteau.png")
    local knifeWidth = knifeImage:getWidth()
    local knifeHeight = knifeImage:getHeight()

    local proj = {
        x = eyeX,
        y = eyeY,
        dirX = dirX,
        dirY = dirY,
        speed = 300,
        distance = 0,
        maxDistance = maxDistance,
        radius = self.rayWidth,
        damage = 10 + self.damage,
        image = knifeImage,
        imageWidth = knifeWidth,
        imageHeight = knifeHeight,
        roomX = roomContext.roomX,
        roomY = roomContext.roomY,
        roomWidth = roomContext.roomWidth,
        roomHeight = roomContext.roomHeight,
        type = "couteau",
        hitEnemies = {},
        player = player
    }

    -- Ajouter le projectile au joueur
    player:addProjectile(proj)

    -- Reset cooldown et rayon actif
    self.shootTimer = self.shootCooldown
    self.rayActive = true
    self.rayTimer = self.rayDuration

    return true
end


function Scream:effect() end

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
        imagePath = "dungeon/masks/assets/scream.png",
        description = "Un masque qui te permet de donner des petit coup de couteau droit dans tes ennemis."
    }
end

return Scream
