local Mask = require("dungeon.masks.mask")
local Medic = setmetatable({}, {__index = Mask})
Medic.__index = Medic

function Medic:new()
    local obj = setmetatable({}, self)
    obj.name = "Medic"
    obj.attackType = "heal"
    
    -- Propriétés du soin
    obj.healAmount = 25          -- HP restaurés
    obj.healDuration = 0.5       -- Durée de l'effet visuel
    
    obj.shootCooldown = 15.0     -- Cooldown
    obj.shootTimer = 0
    
    return obj
end

function Medic:update(dt, player)
    -- Mettre à jour le cooldown de tir
    if self.shootTimer > 0 then
        self.shootTimer = self.shootTimer - dt
    end
end

function Medic:draw(ctx)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", x, y, self.size * (ctx.scale or 1))
end

function Medic:onEquip(player)
    if not player.projectiles then
        player.projectiles = {}
    end
    if not player.equippedMask then
        player.equippedMask = self
    end
end

function Medic:onUnequip(player)
    -- Nettoyer les effets de soin si on déséquipe
    if player.projectiles then
        for i = #player.projectiles, 1, -1 do
            if player.projectiles[i].type == "medic_heal" then
                table.remove(player.projectiles, i)
            end
        end
    end
end

function Medic:canShoot()
    return self.shootTimer <= 0
end

function Medic:shoot(player, dirX, dirY, roomContext)
    -- Vérifier si on peut utiliser le soin
    if not self:canShoot() then
        return false
    end
    
    if not roomContext then
        return false
    end
    
    -- Soigner le joueur instantanément
    player.hp = math.min(player.maxHp, player.hp + self.healAmount)
    
    -- Créer un effet visuel de soin
    local healEffect = {
        x = player.x,
        y = player.y,
        timer = self.healDuration,
        
        -- Métadonnées
        roomX = roomContext.roomX,
        roomY = roomContext.roomY,
        roomWidth = roomContext.roomWidth,
        roomHeight = roomContext.roomHeight,
        type = "medic_heal",
        isHeal = true,
        player = player,  -- Suivre le joueur
        
        -- Effet visuel
        phase = 0
    }
    
    player:addProjectile(healEffect)
    
    -- Réinitialiser le cooldown
    self.shootTimer = self.shootCooldown
    
    return true
end

function Medic:getInfo()
    return {
        name = self.name,
        attackType = self.attackType,
        healAmount = self.healAmount,
        healDuration = self.healDuration,
        shootCooldown = self.shootCooldown,

        imagePath = "dungeon/masks/assets/medic.png",
        description = "Soin instantané pour le joueur. Crée un effet visuel de soin autour du personnage."
    }
end

function Medic:effect()
end

return Medic