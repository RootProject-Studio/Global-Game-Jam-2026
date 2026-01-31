local Mob = require("dungeon.mobs.mob")
local TheMask = setmetatable({}, Mob)
TheMask.__index = TheMask

-- États possibles: "idle", "charging", "stunned"
function TheMask:new(data)
    data.category = "boss"
    data.subtype = "theMask"
    data.speed = 300
    data.size = 40

    local m = Mob.new(self, data)
    m.angle = 0
    m.state = "idle"
    m.stateTimer = 0
    m.chargeSpeed = 400  -- Vitesse pendant la charge
    m.chargeDirection = {x = 0, y = 0}
    m.projectiles = {}
    m.explosions = {}
    m.projectileTimer = 0
    m.projectileInterval = 0.25-- tirer toutes les 0.25s pendant la charge
    m.maxHP = data.maxHP or 100
    m.hp = m.maxHP
    -- Damage settings
    m.dashDamage = data.dashDamage or 10
    m.explosionDamage = data.explosionDamage or 10
    m.dashHitCooldown = data.dashHitCooldown or 0.5
    m.explosionHitCooldown = data.explosionHitCooldown or 1.0
    m.dashHasHit = false
    m.nextChargeTime = 1.5  -- Charge aléatoire entre 2-5 secondes
    return m
end

function TheMask:update(dt, ctx)
    self.stateTimer = self.stateTimer + dt
    if self.state == "idle" then
        -- Wander: choisir une nouvelle cible aléatoire toutes les quelques secondes
        if not self.wanderTarget then
            self.wanderTarget = { x = 0.5, y = 0.5 }
            self.wanderTimer = 0
            self.wanderChangeInterval = math.random(1, 3)
        end

        self.wanderTimer = (self.wanderTimer or 0) + dt
        if self.wanderTimer >= self.wanderChangeInterval then
            self.wanderTarget.x = math.random() -- 0..1
            self.wanderTarget.y = math.random()
            self.wanderTimer = 0
            self.wanderChangeInterval = math.random(1, 3)
        end

        -- Déplacer vers la cible de wander en unités relatives (convertir la vitesse px->rel)
        if ctx and ctx.roomWidth and ctx.roomHeight then
            local dx = self.wanderTarget.x - self.relX
            local dy = self.wanderTarget.y - self.relY
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0.001 then
                local dirx = dx / dist
                local diry = dy / dist
                local relSpeedX = (self.speed * dt) / ctx.roomWidth
                local relSpeedY = (self.speed * dt) / ctx.roomHeight
                self.relX = self.relX + dirx * relSpeedX
                self.relY = self.relY + diry * relSpeedY
            end
        else
            -- fallback: petit mouvement circulaire si pas de ctx
            self.angle = self.angle + dt
            self.relX = 0.5 + math.cos(self.angle) * 0.2
            self.relY = 0.5 + math.sin(self.angle) * 0.2
        end

        -- Vérifier si c'est le moment d'attaquer
        if self.stateTimer >= self.nextChargeTime then
            self:startCharge(ctx)
        end

    elseif self.state == "charging" then
        -- Attaque tournoyante: tourner vite et se diriger vers le joueur
        -- augmenter l'angle pour l'effet de rotation
        self.angle = self.angle + dt * 12 -- vitesse de rotation élevée

        if self.stateTimer < (self.dashDuration or 1) then
            -- Dash: move towards the dash target using the precomputed chargeDirection
            if ctx and ctx.roomWidth and ctx.roomHeight then
                local relDX = (self.chargeDirection.x * self.chargeSpeed * dt) / ctx.roomWidth
                local relDY = (self.chargeDirection.y * self.chargeSpeed * dt) / ctx.roomHeight
                self.relX = math.max(0, math.min(1, self.relX + relDX))
                self.relY = math.max(0, math.min(1, self.relY + relDY))
            else
                -- fallback: small move in chargeDirection if no ctx
                self.relX = self.relX + self.chargeDirection.x * self.chargeSpeed * dt
                self.relY = self.relY + self.chargeDirection.y * self.chargeSpeed * dt
                self.relX = math.max(0, math.min(1, self.relX))
                self.relY = math.max(0, math.min(1, self.relY))
            end
            -- Spawn side projectiles periodically
            self.projectileTimer = self.projectileTimer - dt
            if self.projectileTimer <= 0 then
                self:spawnSideProjectiles(ctx)
                self.projectileTimer = self.projectileInterval
            end

            -- Apply dash damage if colliding with player (once per dash)
            if ctx and ctx.player and not self.dashHasHit then
                local player = ctx.player
                local absX = ctx.roomX + self.relX * ctx.roomWidth
                local absY = ctx.roomY + self.relY * ctx.roomHeight
                local dx = player.x - absX
                local dy = player.y - absY

                local rx = player.hitboxRadiusX or 10
                local ry = player.hitboxRadiusY or 10
                local hitRadiusMultiplier = 1
                local rxx = rx + (self.size or 0) * hitRadiusMultiplier
                local ryy = ry + (self.size or 0) * hitRadiusMultiplier
                local distanceSquared = (dx*dx)/(rxx*rxx) + (dy*dy)/(ryy*ryy)

                if distanceSquared <= 1 then
                    if not player.hitCooldown or player.hitCooldown <= 0 then
                        player.hp = math.max(0, player.hp - (self.dashDamage or 3))
                        player.hitCooldown = self.dashHitCooldown or 0.5
                        self.dashHasHit = true
                    end
                end
            end
        else
            -- Passer à l'état étourdi après 5 secondes
            self:stun()
        end

    elseif self.state == "stunned" then
        -- L'ennemi ne bouge pas et ne peut pas attaquer
        if self.stateTimer >= 2 then
            -- Retour à l'état idle après 3 secondes
            self:returnToIdle()
        end
    end

    -- Mise à jour des projectiles (rel units) + explosions
    if not self.projectiles then self.projectiles = {} end
    if not self.explosions then self.explosions = {} end
    local margin = 0.05
    for i = #self.projectiles, 1, -1 do
        local p = self.projectiles[i]
        p.relX = p.relX + p.dx * dt
        p.relY = p.relY + p.dy * dt
        p.ttl = (p.ttl or 2) - dt

        -- Compute absolute position
        local absX = (ctx and ctx.roomX) and (ctx.roomX + p.relX * ctx.roomWidth) or nil
        local absY = (ctx and ctx.roomY) and (ctx.roomY + p.relY * ctx.roomHeight) or nil

        local hitWall = false

        if absX and absY and ctx and ctx.doors then
            -- Door dimensions must match drawDoors():
            local doorWidth = 60 * _G.gameConfig.scaleX
            local doorHeight = 20 * _G.gameConfig.scaleY
            local centerRoomX = ctx.roomX + ctx.roomWidth / 2
            local centerRoomY = ctx.roomY + ctx.roomHeight / 2

            -- Left wall
            if absX <= ctx.roomX + doorHeight then
                local doorTop = centerRoomY - doorWidth/2
                local doorBottom = centerRoomY + doorWidth/2
                if not ctx.doors.left or absY < doorTop or absY > doorBottom then
                    hitWall = true
                end
            end

            -- Right wall
            if not hitWall and absX >= ctx.roomX + ctx.roomWidth - doorHeight then
                local doorTop = centerRoomY - doorWidth/2
                local doorBottom = centerRoomY + doorWidth/2
                if not ctx.doors.right or absY < doorTop or absY > doorBottom then
                    hitWall = true
                end
            end

            -- Top wall
            if not hitWall and absY <= ctx.roomY + doorHeight then
                local doorLeft = centerRoomX - doorWidth/2
                local doorRight = centerRoomX + doorWidth/2
                if not ctx.doors.top or absX < doorLeft or absX > doorRight then
                    hitWall = true
                end
            end

            -- Bottom wall
            if not hitWall and absY >= ctx.roomY + ctx.roomHeight - doorHeight then
                local doorLeft = centerRoomX - doorWidth/2
                local doorRight = centerRoomX + doorWidth/2
                if not ctx.doors.bottom or absX < doorLeft or absX > doorRight then
                    hitWall = true
                end
            end
        end

        local outOfBounds = p.relX < -margin or p.relX > 1 + margin or p.relY < -margin or p.relY > 1 + margin
        if hitWall or outOfBounds or p.ttl <= 0 then
            -- spawn explosion at projectile position
            self:spawnExplosion(ctx, p.relX, p.relY)
            table.remove(self.projectiles, i)
        end
    end

    -- update explosions
    for i = #self.explosions, 1, -1 do
        local e = self.explosions[i]
        e.timer = e.timer + dt

        -- Damage the player once when inside explosion radius
        if ctx and ctx.player and not e.hasDamaged then
            local player = ctx.player
            local progress = math.min(1, e.timer / e.duration)
            local radius = progress * e.maxRadius * math.min(ctx.roomWidth, ctx.roomHeight)
            local px = ctx.roomX + e.relX * ctx.roomWidth
            local py = ctx.roomY + e.relY * ctx.roomHeight
            local dx = player.x - px
            local dy = player.y - py
            local dist = math.sqrt(dx*dx + dy*dy)
            local playerRadius = player.hitboxRadiusX or 10
            if dist < radius + playerRadius then
                if not player.hitCooldown or player.hitCooldown <= 0 then
                    player.hp = math.max(0, player.hp - (self.explosionDamage or 2))
                    player.hitCooldown = self.explosionHitCooldown or 1.0
                end
                e.hasDamaged = true
            end
        end

        if e.timer >= e.duration then
            table.remove(self.explosions, i)
        end
    end
end

function TheMask:startCharge(ctx)
    -- Calculer la direction et la cible du dash vers la position actuelle du joueur
    local playerRelX, playerRelY = 0.5, 0.5
    if ctx and ctx.playerX and ctx.playerY and ctx.roomX and ctx.roomWidth and ctx.roomHeight then
        playerRelX = (ctx.playerX - ctx.roomX) / ctx.roomWidth
        playerRelY = (ctx.playerY - ctx.roomY) / ctx.roomHeight
    elseif ctx and ctx.player and ctx.player.relX and ctx.player.relY then
        playerRelX = ctx.player.relX
        playerRelY = ctx.player.relY
    end

    -- Clamp
    playerRelX = math.max(0, math.min(1, playerRelX))
    playerRelY = math.max(0, math.min(1, playerRelY))

    local dx = playerRelX - self.relX
    local dy = playerRelY - self.relY
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance > 0 then
        self.chargeDirection.x = dx / distance
        self.chargeDirection.y = dy / distance
    else
        self.chargeDirection.x = 0
        self.chargeDirection.y = 0
    end

    -- Dash target (relative) and duration
    self.dashTarget = { x = playerRelX, y = playerRelY }
    self.dashDuration = 1 -- seconds

    self.state = "charging"
    self.stateTimer = 0
    -- Reset projectile timer to fire immediately
    self.projectileTimer = 0
    -- Reset dash hit flag so damage can be applied once during this dash
    self.dashHasHit = false
end

function TheMask:stun()
    self.state = "stunned"
    self.stateTimer = 0
    self.chargeDirection = {x = 0, y = 0}
end


function TheMask:spawnSideProjectiles(ctx)
    -- Crée deux projectiles perpendiculaires à la direction de charge
    if not ctx or not ctx.roomWidth or not ctx.roomHeight then return end

    local dx = self.chargeDirection.x
    local dy = self.chargeDirection.y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist == 0 then return end
    dx = dx / dist
    dy = dy / dist

    -- Perp vector
    local px = -dy
    local py = dx

    local projSpeedPx = 180 -- px/s
    local projSizeRel = 0.02

    for sign = -1, 1, 2 do
        local offx = self.relX + px * (sign * (self.size / ctx.roomWidth) + 0)
        local offy = self.relY + py * (sign * (self.size / ctx.roomHeight) + 0)

        local p = {
            relX = offx,
            relY = offy,
            dx = (px * sign * projSpeedPx) / ctx.roomWidth,
            dy = (py * sign * projSpeedPx) / ctx.roomHeight,
            ttl = math.random(1,2), -- seconds before auto-explode
            size = projSizeRel,
            color = {1,1,0}
        }

        table.insert(self.projectiles, p)
    end
end

function TheMask:spawnExplosion(ctx, relX, relY)
    if not self.explosions then self.explosions = {} end
    local e = {
        relX = relX,
        relY = relY,
        timer = 0,
        duration = 0.5,
        maxRadius = 0.12, -- relative to min(roomWidth,roomHeight)
        color = {1, 0.6, 0}
    }
    e.hasDamaged = false
    table.insert(self.explosions, e)
end

function TheMask:returnToIdle()
    self.state = "idle"
    self.stateTimer = 0
    self.nextChargeTime = math.random(2, 5)  -- Nouvelle charge aléatoire
end

function TheMask:draw(ctx)
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    -- Couleur change selon l'état
    if self.state == "charging" then
        love.graphics.setColor(1, 0.5, 0)  -- Orange pendant la charge
    elseif self.state == "stunned" then
        love.graphics.setColor(0.5, 0.5, 0.5)  -- Gris pendant l'étourdissement
    else
        love.graphics.setColor(1, 0, 0)  -- Rouge normal
    end

    love.graphics.circle("fill", x, y, self.size)
    -- Barre de vie (même style que DarkVador)
    if self.maxHP and self.hp then
        local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
        local margin = 20 * scale
        local maxWidth = 400 * scale
        local height = 20 * scale
        local x0 = (_G.gameConfig.windowWidth - maxWidth) / 2
        local y0 = margin

        love.graphics.setColor(0.5,0,0)
        love.graphics.rectangle("fill", x0, y0, maxWidth, height)

        love.graphics.setColor(0,1,0)
        love.graphics.rectangle("fill", x0, y0, maxWidth * (self.hp / self.maxHP), height)

        love.graphics.setColor(0,0,0)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x0, y0, maxWidth, height)
    end
end

-- Dessiner projectiles
function TheMask:drawProjectiles(ctx)
    for _, p in ipairs(self.projectiles) do
        love.graphics.setColor(p.color)
        local px = ctx.roomX + p.relX * ctx.roomWidth
        local py = ctx.roomY + p.relY * ctx.roomHeight
        love.graphics.circle("fill", px, py, p.size * math.min(ctx.roomWidth, ctx.roomHeight))
    end
end

-- Dessiner explosions
function TheMask:drawExplosions(ctx)
    if not self.explosions then return end
    for _, e in ipairs(self.explosions) do
        local progress = math.min(1, e.timer / e.duration)
        local radius = progress * e.maxRadius * math.min(ctx.roomWidth, ctx.roomHeight)
        local alpha = 1 - progress
        love.graphics.setColor(e.color[1], e.color[2], e.color[3], alpha)
        local px = ctx.roomX + e.relX * ctx.roomWidth
        local py = ctx.roomY + e.relY * ctx.roomHeight
        love.graphics.circle("fill", px, py, radius)
    end
    love.graphics.setColor(1,1,1,1)
end

-- Appeler drawProjectiles depuis draw principal
local _old_draw = TheMask.draw
function TheMask:draw(ctx)
    _old_draw(self, ctx)
    if self.projectiles then self:drawProjectiles(ctx) end
    if self.explosions then self:drawExplosions(ctx) end
end

return TheMask
