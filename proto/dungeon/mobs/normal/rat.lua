local Mob = require("dungeon.mobs.mob")
local Rat = setmetatable({}, {__index = Mob})
Rat.__index = Rat

function Rat:new(data)
    data.category = "normal"
    data.subtype = "rat"
    data.speed = 30          -- pixels par seconde
    data.size = 14           -- rayon du Rat

    local m = Mob.new(self, data)
    m.dir = math.random() * 2 * math.pi  -- direction aléatoire
    return m
end

function Rat:update(dt, ctx)
    -- Calcul du mouvement relatif
    local dx = math.cos(self.dir) * self.speed * dt / ctx.roomWidth
    local dy = math.sin(self.dir) * self.speed * dt / ctx.roomHeight

    self.relX = self.relX + dx
    self.relY = self.relY + dy

    -- Rebonds sur les murs
    local bounced = false
    if self.relX < 0 then
        self.relX = 0
        self.dir = math.pi - self.dir
        bounced = true
    elseif self.relX > 1 then
        self.relX = 1
        self.dir = math.pi - self.dir
        bounced = true
    end

    if self.relY < 0 then
        self.relY = 0
        self.dir = -self.dir
        bounced = true
    elseif self.relY > 1 then
        self.relY = 1
        self.dir = -self.dir
        bounced = true
    end

    -- Normaliser l'angle pour éviter les débordements
    if bounced then
        self.dir = (self.dir + 2 * math.pi) % (2 * math.pi)
    end
end

function Rat:draw(ctx)
    -- position absolue dans la salle
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    love.graphics.setColor(0.3, 0.8, 0.8)
    love.graphics.circle("fill", x, y, self.size)
end

return Rat
