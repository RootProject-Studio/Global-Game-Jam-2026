-- mob.lua
local Mob = {}

-- Types de mobs
Mob.TYPES = {
    NORMAL = "normal",
    BOSS = "boss"
}

-- Création d'un mob
function Mob:new(type, name, hp, damage)
    local mob = {}
    setmetatable(mob, self)
    self.__index = self

    mob.type = type or self.TYPES.NORMAL
    mob.name = name or (mob.type == self.TYPES.BOSS and "Boss" or "Goblin")
    mob.hp = hp or (mob.type == self.TYPES.BOSS and 100 or 20)
    mob.damage = damage or (mob.type == self.TYPES.BOSS and 15 or 5)

    return mob
end

return Mob
