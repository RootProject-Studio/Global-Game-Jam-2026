local MaskManager = {}
MaskManager.__index = MaskManager

function MaskManager:new()
    local m = setmetatable({}, self)

    m.open = false

    -- 2 slots max
    m.slots = { nil, nil }

    -- slot actuellement sélectionné (1 ou 2)
    m.selectedSlot = 1

    return m
end

function MaskManager:toggle()
    self.open = not self.open
end

function MaskManager:close()
    self.open = false
end

function MaskManager:selectNext()
    self:moveSelection("right")
end

function MaskManager:selectPrev()
    self:moveSelection("left")
end


function MaskManager:moveSelection(dir)
    if dir == "left" then
        self.selectedSlot = math.max(1, self.selectedSlot - 1)
    elseif dir == "right" then
        self.selectedSlot = math.min(2, self.selectedSlot + 1)
    end
end

function MaskManager:equip(mask, slot)
    slot = slot or self.selectedSlot
    self.slots[slot] = mask
end

function MaskManager:unequip(slot)
    if not slot or slot < 1 or slot > 2 then
        return  -- slot invalide, rien à faire
    end

    -- Ne pas déséquiper si l'autre slot est vide
    local otherSlot = slot == 1 and 2 or 1
    if self.slots[otherSlot] ~= nil then
        self.slots[slot] = nil
    end
end


function MaskManager:startPickup(mask)
    self.pickupMode = true        -- on est en train de placer un masque
    self.pickupMask = mask        -- le masque à placer
    self.open = true              -- on force l'ouverture de la fenêtre
    self.selectedSlot = 1         -- slot initial sélectionné
end

function MaskManager:confirmPickup(player)
    if not self.pickupMode or not self.pickupMask then return end
    self.slots[self.selectedSlot] = self.pickupMask
    self.pickupMask:onEquip(player)
    
    -- Réinitialiser l'état
    self.pickupMask = nil
    self.pickupMode = false
    self.open = false   -- fermer le menu après placement
end


function MaskManager:cancelPickup()
    if self.pickupMode and self.pickupMask then
        self.pickupMask = nil
        self.pickupMode = false
        self.open = false   -- fermer le menu si on annule
    end
end




return MaskManager
