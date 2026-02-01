local Mask = require("dungeon.masks.mask")
local PlagueDoctor = setmetatable({}, {__index = Mask})
PlagueDoctor.__index = PlagueDoctor

function PlagueDoctor:new()
    local obj = setmetatable({}, self)
    obj.name = "PlagueDoctor"
    obj.attackType = "aura"
    obj.damage = 3  -- Dégâts par tick (faibles mais continus)
    
    -- Propriétés de l'aura
    obj.auraRadius = 120       -- Rayon de l'aura de poison
    obj.auraDuration = 5.0     -- Durée de l'aura active (secondes)
    obj.auraTickRate = 0.5     -- Intervalle entre chaque tick de dégâts (0.5s = 2 dégâts/sec)
    
    obj.shootCooldown = 8.0    -- Cooldown entre deux activations
    obj.shootTimer = 0
    
    -- État de l'aura
    obj.auraActive = false
    obj.auraTimer = 0
    
    return obj
end

function PlagueDoctor:update(dt, player)
    -- Mettre à jour le cooldown de tir
    if self.shootTimer > 0 then
        self.shootTimer = self.shootTimer - dt
    end
    
    -- Mettre à jour le timer de l'aura
    if self.auraActive then
        self.auraTimer = self.auraTimer - dt
        if self.auraTimer <= 0 then
            self.auraActive = false
        end
    end
end

function PlagueDoctor:draw(ctx)
    love.graphics.setColor(0.2, 0.4, 0.2)
    love.graphics.circle("fill", x, y, self.size * (ctx.scale or 1))
end

function PlagueDoctor:onEquip(player)
    if not player.projectiles then
        player.projectiles = {}
    end
    if not player.equippedMask then
        player.equippedMask = self
    end
end

function PlagueDoctor:onUnequip(player)
    -- Nettoyer l'aura si on déséquipe
    if player.projectiles then
        for i = #player.projectiles, 1, -1 do
            if player.projectiles[i].type == "plague_aura" then
                table.remove(player.projectiles, i)
            end
        end
    end
    self.auraActive = false
end

function PlagueDoctor:canShoot()
    return self.shootTimer <= 0
end

function PlagueDoctor:shoot(player, dirX, dirY, roomContext)
    -- Vérifier si on peut activer l'aura
    if not self:canShoot() then
        return false
    end
    
    if not roomContext then
        return false
    end
    
    -- Créer l'aura de poison autour du joueur
    local aura = {
        -- Position (suit le joueur)
        x = player.x,
        y = player.y,
        
        -- Propriétés de l'aura
        radius = self.auraRadius,
        damage = self.damage,
        timer = self.auraDuration,
        tickRate = self.auraTickRate,
        tickTimer = 0,  -- Timer pour les ticks de dégâts
        
        -- Métadonnées
        roomX = roomContext.roomX,
        roomY = roomContext.roomY,
        roomWidth = roomContext.roomWidth,
        roomHeight = roomContext.roomHeight,
        type = "plague_aura",
        isAura = true,
        player = player,  -- Référence au joueur pour suivre sa position
        
        -- Tracker pour les dégâts par tick
        enemyTickTimers = {}  -- {[mob] = tickTimer}
    }
    
    player:addProjectile(aura)
    
    -- Activer l'état de l'aura
    self.auraActive = true
    self.auraTimer = self.auraDuration
    
    -- Réinitialiser le cooldown
    self.shootTimer = self.shootCooldown
    
    return true
end

function PlagueDoctor:effect()
end

return PlagueDoctor