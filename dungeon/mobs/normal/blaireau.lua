local Mob = require("dungeon.mobs.mob")
local Blaireau = setmetatable({}, {__index = Mob})
Blaireau.__index = Blaireau

function Blaireau:new(data)
    data.category = "normal"
    data.subtype = "Blaireau"
    data.speed = 60          -- pixels par seconde
    data.size = 14 * 2           -- rayon du Blaireau
    data.maxHP = data.maxHP or 30  -- PV max
    data.damage = data.damage or 3  -- dégâts infligés au joueur


    local m = Mob.new(self, data)
    m.attackCooldown = 0.5   -- temps entre deux attaques
    m.attackTimer = 0         -- timer interne pour l'attaque

    m.dir = math.random() * 2 * math.pi  -- direction aléatoire
    return m
end

function Blaireau:update(dt, ctx)
    local player = ctx.player
    if not player or not ctx.playerX or not ctx.playerY then return end

    -- Position du Blaireau en pixels
    local myX = self.relX * ctx.roomWidth
    local myY = self.relY * ctx.roomHeight

    -- Position du joueur en pixels
    local playerX = ctx.playerX - ctx.roomX
    local playerY = ctx.playerY - ctx.roomY

    local dx = playerX - myX
    local dy = playerY - myY
    local dist = math.sqrt(dx*dx + dy*dy)

    -- Déplacement du Blaireau vers le joueur
    if dist > 0 then
        local vx = dx / dist
        local vy = dy / dist

        local move_px = self.speed * dt
        self.relX = self.relX + (vx * move_px / ctx.roomWidth)
        self.relY = self.relY + (vy * move_px / ctx.roomHeight)
    end

    -- Clamp pour rester dans la salle
    self.relX = math.max(0, math.min(1, self.relX))
    self.relY = math.max(0, math.min(1, self.relY))

    -- Timer pour attaques
    self.attackTimer = (self.attackTimer or 0) + dt
    local hitboxMultiplier = 2  -- facteur pour agrandir la hitbox
    local attackRange = (self.size + (player.size or 8)) * hitboxMultiplier

    if dist <= attackRange then
        if self.attackTimer >= (self.attackCooldown or 0.5) and (not player.hitCooldown or player.hitCooldown <= 0) then
            player.hp = math.max(0, player.hp - (self.damage or 1))
            player.hitCooldown = 0.5 -- cooldown d’invincibilité du joueur
            self.attackTimer = 0
        end
    end

end



function Blaireau:draw(ctx)
    -- position absolue dans la salle
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    love.graphics.setColor(0.3, 0.8, 0.8)
    love.graphics.circle("fill", x, y, self.size)

    -- Barre de vie
    if self.maxHP > 1 then
        local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)

        local barWidth = self.size * scale * 2
        local barHeight = 3 * scale
        love.graphics.rectangle("fill", x - barWidth/2, y - self.size*scale - 6, barWidth, barHeight)
        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", x - barWidth/2, y - self.size*scale - 6, barWidth * (self.hp/self.maxHP), barHeight)

    end
end

return Blaireau
