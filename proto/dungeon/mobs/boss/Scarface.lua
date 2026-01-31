local Mob = require("dungeon.mobs.mob")
local Scarface = setmetatable({}, Mob)
Scarface.__index = Scarface

function Scarface:new(data)
    data.category = "boss"
    data.subtype  = "scarface"
    data.speed    = 0
    data.size     = 38
    data.maxHP    = data.maxHP or 120

    local m = Mob.new(self, data)

    -- Timings
    m.underworldDuration = 5.0   -- durée sous terre
    m.stunDuration       = 2.0   -- durée du stun après remontée
    m.trailLifetime      = 5.0   -- combien de temps la traînée reste visible
    m.surfaceDelay       = 1.0   -- pause en surface avant de replonger

    -- State machine
    m.state      = "surface"     -- surface | underground | emerging | stunned
    m.stateTimer = m.surfaceDelay

    -- Déplacement sous terre
    m.dx = 0
    m.dy = 0
    m.moveSpeed = 0.5          -- vitesse relative par seconde sous terre

    -- Traînée : liste de {relX, relY, timer}
    m.trail = {}
    m.trailInterval = 0.05       -- un point tous les 50ms
    m.trailAccumulator = 0

    -- Point de remontée
    m.emergePoint = nil
    m.emergeHit   = false        -- true quand le dégât de remontée a été appliqué

    -- Dégâts
    m.trailDamage   = 1          -- dégâts par contact traînée
    m.emergeDamage  = 2          -- dégâts de remontée
    m.trailHitRadius = 0.04      -- rayon de collision d'un point de traînée (relatif)

    return m
end

-- ─────────────────────────────────────────────
-- UPDATE
-- ─────────────────────────────────────────────
function Scarface:update(dt, ctx)
    if self.state == "surface" then
        self:updateSurface(dt, ctx)

    elseif self.state == "underground" then
        self:updateUnderground(dt, ctx)

    elseif self.state == "emerging" then
        self:updateEmerging(dt, ctx)

    elseif self.state == "stunned" then
        self:updateStunned(dt, ctx)
    end

    -- Mettre à jour les timers de la traînée (disparition progressive)
    self:updateTrail(dt)
end

-- ── Surface : attend puis plonge ─────────────
function Scarface:updateSurface(dt, ctx)
    self.stateTimer = self.stateTimer - dt

    if self.stateTimer <= 0 then
        self:dive()
    end
end

-- ── Sous terre : se déplace, trace la traînée ───
function Scarface:updateUnderground(dt, ctx)
    self.stateTimer = self.stateTimer - dt

    -- Déplacer le boss
    self.relX = self.relX + self.dx * self.moveSpeed * dt
    self.relY = self.relY + self.dy * self.moveSpeed * dt

    -- Clamper la position dans la salles
    if self.relX <= 0.05 or self.relX >= 0.95 then
        self.dx = -self.dx
        self.relX = math.max(0.05, math.min(0.95, self.relX))
    end
    if self.relY <= 0.05 or self.relY >= 0.95 then
        self.dy = -self.dy
        self.relY = math.max(0.05, math.min(0.95, self.relY))
    end

    -- Ajouter des points de traînée à intervalles réguliers
    self.trailAccumulator = self.trailAccumulator + dt
    if self.trailAccumulator >= self.trailInterval then
        self.trailAccumulator = 0
        table.insert(self.trail, {
            relX  = self.relX,
            relY  = self.relY,
            timer = self.trailLifetime
        })
    end

    -- Collision joueur avec la traînée pendant le déplacement
    if ctx.player then
        self:checkTrailCollision(ctx.player, ctx)
    end

    -- Fin du déplacement sous terre → préparer remontée
    if self.stateTimer <= 0 then
        self.emergePoint = { relX = self.relX, relY = self.relY }
        self.emergeHit   = false
        self.state       = "emerging"
        self.stateTimer  = 0.3  -- petit délai visuel avant le stun
    end
end

-- ── Remontée : apparaît, fait dégâts une fois, puis stun ───
function Scarface:updateEmerging(dt, ctx)
    self.stateTimer = self.stateTimer - dt

    -- Appliquer le dégât de remontée une seule fois
    if not self.emergeHit and ctx.player then
        self:checkEmergeCollision(ctx.player, ctx)
        self.emergeHit = true
    end

    if self.stateTimer <= 0 then
        self.state      = "stunned"
        self.stateTimer = self.stunDuration
    end
end

-- ── Stunned : immobile, puis loop ───────────
function Scarface:updateStunned(dt, ctx)
    self.stateTimer = self.stateTimer - dt

    if self.stateTimer <= 0 then
        self.state      = "surface"
        self.stateTimer = self.surfaceDelay
    end
end

-- ─────────────────────────────────────────────
-- TRANSITIONS
-- ─────────────────────────────────────────────

-- Plonger sous terre : choisit une direction aléatoire
function Scarface:dive()
    -- Angle aléatoire
    local angle = math.random() * math.pi * 2
    self.dx = math.cos(angle)
    self.dy = math.sin(angle)

    self.trail             = {}   -- réinitialiser la traînée
    self.trailAccumulator  = 0
    self.emergePoint=nil
    self.state             = "underground"
    self.stateTimer        = self.underworldDuration
end

-- ─────────────────────────────────────────────
-- TRAÎNÉE
-- ─────────────────────────────────────────────

-- Faire disparaître les points de traînée après trailLifetime
function Scarface:updateTrail(dt)
    for i = #self.trail, 1, -1 do
        self.trail[i].timer = self.trail[i].timer - dt
        if self.trail[i].timer <= 0 then
            table.remove(self.trail, i)
        end
    end
end

-- ─────────────────────────────────────────────
-- COLLISIONS
-- ─────────────────────────────────────────────

-- Collision joueur avec les points de traînée (pendant underground)
function Scarface:checkTrailCollision(player, ctx)
    for _, point in ipairs(self.trail) do
        local dx = player.x - (ctx.roomX + point.relX * ctx.roomWidth)
        local dy = player.y - (ctx.roomY + point.relY * ctx.roomHeight)
        local dist = math.sqrt(dx*dx + dy*dy)

        local hitRadius = self.trailHitRadius * math.max(ctx.roomWidth, ctx.roomHeight)

        if dist < hitRadius + (player.hitboxRadiusX or 10) then
            if not player.hitCooldown or player.hitCooldown <= 0 then
                player.hp = math.max(0, player.hp - self.trailDamage)
                player.hitCooldown = 0.5
            end
        end
    end
end

-- Collision joueur avec le point de remontée (une seule fois)
function Scarface:checkEmergeCollision(player, ctx)
    if not self.emergePoint then return end

    local ex = ctx.roomX + self.emergePoint.relX * ctx.roomWidth
    local ey = ctx.roomY + self.emergePoint.relY * ctx.roomHeight

    local dx = player.x - ex
    local dy = player.y - ey
    local dist = math.sqrt(dx*dx + dy*dy)

    -- Rayon de remontée plus grand que la traînée (zone de danger)
    local emergeRadius = 0.08 * math.max(ctx.roomWidth, ctx.roomHeight)

    if dist < emergeRadius + (player.hitboxRadiusX or 10) then
        if not player.hitCooldown or player.hitCooldown <= 0 then
            player.hp = math.max(0, player.hp - self.emergeDamage)
            player.hitCooldown = 1.0
        end
    end
end


function Scarface:draw(ctx)
    local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)

    -- ── Traînée (toujours visible) ───────────
    for _, point in ipairs(self.trail) do
        local alpha = point.timer / self.trailLifetime
        love.graphics.setColor(0.6, 0.1, 0.1, alpha)
        local px = ctx.roomX + point.relX * ctx.roomWidth
        local py = ctx.roomY + point.relY * ctx.roomHeight
        love.graphics.circle("fill", px, py, self.trailHitRadius * math.max(ctx.roomWidth, ctx.roomHeight)*1.2)
    end

    -- ── Point de remontée (indice visuel) ────
    if self.emergePoint and (self.state == "underground" or self.state == "emerging") then
        local t = self.stateTimer
        local pulse = 0.5 + 0.5 * math.sin(t * 8)
        love.graphics.setColor(1, 0.8, 0, 0.4 + 0.4 * pulse)
        local ex = ctx.roomX + self.emergePoint.relX * ctx.roomWidth
        local ey = ctx.roomY + self.emergePoint.relY * ctx.roomHeight
        local emergeRadius = 0.12 * math.max(ctx.roomWidth, ctx.roomHeight)
        love.graphics.circle("fill", ex, ey, emergeRadius)
    end

    -- ── Corps du boss (invisible sous terre) ─
    if self.state ~= "underground" then
        local x = ctx.roomX + self.relX * ctx.roomWidth
        local y = ctx.roomY + self.relY * ctx.roomHeight

        if self.state == "stunned" then
            love.graphics.setColor(0.8, 0.2, 0.2, 0.5)
            love.graphics.circle("fill", x, y, self.size * scale * 1.3)
        end

        love.graphics.setColor(0.15, 0.15, 0.25)
        love.graphics.circle("fill", x, y, self.size * scale)

        love.graphics.setColor(0.7, 0.1, 0.1)
        love.graphics.setLineWidth(3)
        love.graphics.line(
            x - self.size * scale * 0.3, y - self.size * scale * 0.6,
            x + self.size * scale * 0.1, y + self.size * scale * 0.2
        )
    end

    -- ── Barre de vie ─────────────────────────
    if self.maxHP and self.hp then
        local margin   = 20 * scale
        local maxWidth = 400 * scale
        local height   = 20 * scale
        local x0 = (_G.gameConfig.windowWidth - maxWidth) / 2
        local y0 = margin

        love.graphics.setColor(0.5, 0, 0)
        love.graphics.rectangle("fill", x0, y0, maxWidth, height)

        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle("fill", x0, y0, maxWidth * (self.hp / self.maxHP), height)

        love.graphics.setColor(0, 0, 0)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x0, y0, maxWidth, height)
    end
end

return Scarface

