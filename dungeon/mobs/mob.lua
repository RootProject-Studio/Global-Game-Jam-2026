local Mob = {}
Mob.__index = Mob

function Mob:new(data)
    local m = setmetatable({}, self)

    m.category = data.category      -- "normal" | "boss"
    m.subtype  = data.subtype

    -- position relative (0 → 1)
    m.relX = data.relX or 0.5
    m.relY = data.relY or 0.5

    m.speed = data.speed or 40
    m.size  = data.size  or 15


    -- PV
    m.maxHP = data.maxHP or 1        -- par défaut 1
    m.hp = m.maxHP

    m.dropChance = data.dropChance or 1
    self.droppedItem = nil

    return m
end

function Mob:update(dt, ctx)
    -- redéfini dans les sous-types
end


function Mob:takeDamage(amount)
    self.hp = math.max(self.hp - amount, 0)
end

function Mob:isDead()
    return self.hp <= 0
end

-- Appeler cette fonction quand le mob meurt
function Mob:onDeath()
    -- Chance de drop
    if math.random() < self.dropChance then
        local masks = {"cyclope", "ffp2", "scream"}
        local randomMask = masks[math.random(#masks)]
        
        -- Créer l'item au centre du mob
        local MaskItem = require("dungeon.masks.maskItem")
        self.droppedItem = MaskItem:new(randomMask, self.relX, self.relY)
        return self.droppedItem
    end
    return nil
end


function Mob:draw(ctx)
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    love.graphics.circle("fill", x, y, self.size * ctx.scale)
end

return Mob
