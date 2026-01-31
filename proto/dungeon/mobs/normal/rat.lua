local Mob = require("dungeon.mobs.mob")
local Rat = setmetatable({}, {__index = Mob})
Rat.__index = Rat

function Rat:new(data)
    data.category = "normal"
    data.subtype = "rat"
    data.speed = 60          -- pixels par seconde
    data.size = 14           -- rayon du Rat

    local m = Mob.new(self, data)
    m.dir = math.random() * 2 * math.pi  -- direction aléatoire
    return m
end

function Rat:update(dt, ctx)
    -- Se diriger en ligne droite vers la position du joueur.
    -- On travaille en pixels pour garder une vitesse cohérente,
    -- puis on reconvertit en coordonnées relatives (0..1).
    if not ctx.playerX or not ctx.playerY then
        return
    end

    -- position du mob en pixels depuis l'origine de la salle
    local myX = self.relX * ctx.roomWidth
    local myY = self.relY * ctx.roomHeight

    -- position du joueur en pixels relative à l'origine de la salle
    local targetX = ctx.playerX - ctx.roomX
    local targetY = ctx.playerY - ctx.roomY

    local dx = targetX - myX
    local dy = targetY - myY
    local dist = math.sqrt(dx*dx + dy*dy)

    if dist > 0 then
        local vx = dx / dist
        local vy = dy / dist

        local move_px = self.speed * dt
        local moveX = vx * move_px
        local moveY = vy * move_px

        self.relX = self.relX + (moveX / ctx.roomWidth)
        self.relY = self.relY + (moveY / ctx.roomHeight)
    end

    -- Clamp pour rester dans la salle
    if self.relX < 0 then self.relX = 0 end
    if self.relX > 1 then self.relX = 1 end
    if self.relY < 0 then self.relY = 0 end
    if self.relY > 1 then self.relY = 1 end
end

function Rat:draw(ctx)
    -- position absolue dans la salle
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    love.graphics.setColor(0.3, 0.8, 0.8)
    love.graphics.circle("fill", x, y, self.size)
end

return Rat
