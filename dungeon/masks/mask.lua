local Mask = {}
Mask.__index = Mask

function Mask:new()
    local obj = setmetatable({}, self)
    obj.name = "Base Mask"
    obj.damage = 0
    obj.cooldown = 1
    return obj
end

function Mask:update(dt)
end

function Mask:draw(ctx)
end

function Mask:onEquip(player)
    -- Appelé quand le mask est équipé
end

function Mask:onUnequip(player)
    -- Appelé quand le mask est déséquipé
end

function Mask:getDamageBonus()
    -- Retourner les dégâts bonus apportés par ce mask
    return self.damage or 0
end

function Mask:getLifeBonus()
    return self.life or 0
end

function Mask:effect()
end

return Mask