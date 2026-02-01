local Mask = require("dungeon.masks.mask")
local Templar = setmetatable({}, {__index = Mask})
Templar.__index = Templar

function Templar:new()
    local obj = setmetatable({}, self)
    obj.name = "Templar"
    obj.attackType = "shield"
    obj.damage = 10  -- Dégâts du bouclier
    
    -- Propriétés du bouclier
    obj.shieldRadius = 80     -- Rayon du bouclier
    obj.shieldDuration = 2.0   -- Durée du bouclier (secondes)
    obj.knockbackForce = 80   -- Force de répulsion des ennemis
    
    obj.shootCooldown = 8.0    -- Cooldown entre deux activations
    obj.shootTimer = 0
    
    -- État du bouclier
    obj.shieldActive = false
    obj.shieldTimer = 0
    
    return obj
end

function Templar:update(dt, player)
    -- Mettre à jour le cooldown de tir
    if self.shootTimer > 0 then
        self.shootTimer = self.shootTimer - dt
    end
    
    -- Mettre à jour le timer du bouclier
    if self.shieldActive then
        self.shieldTimer = self.shieldTimer - dt
        
        if not player.hitCooldown or player.hitCooldown < self.shieldTimer then
            player.hitCooldown = self.shieldTimer
        end
        if self.shieldTimer <= 0 then
            self.shieldActive = false
        end
    end
end

function Templar:draw(ctx)
    love.graphics.setColor(0.8, 0.8, 0.9)
    love.graphics.circle("fill", x, y, self.size * (ctx.scale or 1))
end

function Templar:onEquip(player)
    if not player.projectiles then
        player.projectiles = {}
    end
    if not player.equippedMask then
        player.equippedMask = self
    end
end

function Templar:onUnequip(player)
    -- Nettoyer le bouclier si on déséquipe
    if player.projectiles then
        for i = #player.projectiles, 1, -1 do
            if player.projectiles[i].type == "templar_shield" then
                table.remove(player.projectiles, i)
            end
        end
    end
    self.shieldActive = false
end

function Templar:canShoot()
    return self.shootTimer <= 0
end

function Templar:shoot(player, dirX, dirY, roomContext)
    -- Vérifier si on peut activer le bouclier
    if not self:canShoot() then
        return false
    end
    
    if not roomContext then
        return false
    end
    
    -- Créer le bouclier autour du joueur
    local shield = {
        -- Position (suit le joueur)
        x = player.x,
        y = player.y,
        
        -- Propriétés du bouclier
        radius = self.shieldRadius,
        damage = self.damage,
        knockbackForce = self.knockbackForce,
        timer = self.shieldDuration,
        
        -- Métadonnées
        roomX = roomContext.roomX,
        roomY = roomContext.roomY,
        roomWidth = roomContext.roomWidth,
        roomHeight = roomContext.roomHeight,
        type = "templar_shield",
        isShield = true,
        player = player,  -- Référence au joueur pour suivre sa position
        
        -- Tracker pour éviter les dégâts multiples
        hitEnemies = {}  -- {[mob] = true} - hit une seule fois par activation
    }
    
    player:addProjectile(shield)
    
    -- Activer l'état du bouclier
    self.shieldActive = true
    self.shieldTimer = self.shieldDuration
    player.hitCooldown = self.shieldDuration
    
    -- Réinitialiser le cooldown
    self.shootTimer = self.shootCooldown
    
    return true
end

function Templar:effect()
end

function Templar:getInfo()
    return {
        name = self.name,
        attackType = self.attackType,
        damage = self.damage,
        shieldRadius = self.shieldRadius,
        shieldDuration = self.shieldDuration,
        knockbackForce = self.knockbackForce,
        shootCooldown = self.shootCooldown,
        shieldActive = self.shieldActive,
        shieldTimer = self.shieldTimer,

        imagePath = "dungeon/masks/assets/templar.png",  -- chemin vers l'image du masque
        description = "Active un bouclier autour du joueur qui repousse et inflige des dégâts aux ennemis proches" -- courte description
    }
end


return Templar