local Mob = require("dungeon.mobs.mob")
local Pigeon = setmetatable({}, {__index = Mob})
Pigeon.__index = Pigeon

function Pigeon:new(data)
    data.category = "normal"
    data.subtype = "pigeon"
    data.speed = 60          -- pixels par seconde
    data.size = 14           -- rayon du Pigeon

    local m = Mob.new(self, data)
    m.dir = math.random() * 2 * math.pi  -- direction aléatoire

    -- State machine for idle/dash/return
    m.state = "idle"
    m.dashTriggerDist = data.dashTriggerDist or 150 -- zone pour déclencher le dash (px)
    m.dashTime = data.dashTime or 0.35  -- durée du dash
    m.dashSpeed = data.dashSpeed or 240 -- pixels/s pendant le dash
    m.returnSpeed = data.returnSpeed or m.speed
    m.idleDist = data.idleDist or 120   -- distance de maintien autour du joueur (px)
    m.attackCooldown = data.attackCooldown or 0.5 -- cooldown entre les attaques (s)
    m.attackTimer = 0
    m.canAttack = true

    -- angle relatif autour du joueur où le pigeon se tient (conserve son angle initial)
    m.idleAngle = math.atan2((m.relY - 0.5), (m.relX - 0.5))
    if not m.idleAngle or m.idleAngle == 0 then m.idleAngle = math.random() * 2 * math.pi end
    m.dashTimer = 0
    m.dashDirX = 0
    m.dashDirY = 0
    return m
end

function Pigeon:update(dt, ctx)
    -- Behaviour: idle (hold position at a distance) -> if player enters dashTriggerDist => dash -> return
    if not ctx.playerX or not ctx.playerY then return end

    -- absolute positions in pixels relative to room origin
    local myX = self.relX * ctx.roomWidth
    local myY = self.relY * ctx.roomHeight
    local playerX = ctx.playerX - ctx.roomX
    local playerY = ctx.playerY - ctx.roomY

    -- Distance to player
    local toPlayerX = playerX - myX
    local toPlayerY = playerY - myY
    local distToPlayer = math.sqrt(toPlayerX*toPlayerX + toPlayerY*toPlayerY)

    -- Update attack cooldown
    if not self.canAttack then
        self.attackTimer = self.attackTimer + dt
        if self.attackTimer >= self.attackCooldown then
            self.canAttack = true
            self.attackTimer = 0
        end
    end

    -- compute current anchor position around player using idleAngle
    local anchorX = playerX + math.cos(self.idleAngle) * self.idleDist
    local anchorY = playerY + math.sin(self.idleAngle) * self.idleDist

    if self.state == "idle" then
        -- move smoothly toward anchor
        local dx = anchorX - myX
        local dy = anchorY - myY
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 0.1 then
            local step = math.min(self.speed * dt, dist)
            myX = myX + (dx / dist) * step
            myY = myY + (dy / dist) * step
        end

        -- Check if pigeon can attack: either player is in dashTriggerDist OR in direct collision (very close)
        local canTriggerDash = false
        if distToPlayer <= self.dashTriggerDist then
            canTriggerDash = true
        elseif distToPlayer <= (self.size + 8) then  -- collision range
            canTriggerDash = true
        end

        -- If player triggers attack and cooldown is ready, start dash
        if canTriggerDash and self.canAttack then
            -- start dash toward player's current position
            local ddx = (playerX - myX)
            local ddy = (playerY - myY)
            local dlen = math.sqrt(ddx*ddx + ddy*ddy)
            if dlen == 0 then dlen = 0.0001 end
            self.dashDirX = ddx / dlen
            self.dashDirY = ddy / dlen
            self.state = "dash"
            self.dashTimer = 0
            self.canAttack = false
        end

    elseif self.state == "dash" then
        -- move fast towards dash direction (ignore walls, just move)
        local move = self.dashSpeed * dt
        myX = myX + self.dashDirX * move
        myY = myY + self.dashDirY * move
        self.dashTimer = self.dashTimer + dt

        -- stop dash after dashTime (or if reached player closely)
        local pdx = playerX - myX
        local pdy = playerY - myY
        if self.dashTimer >= self.dashTime or (pdx*pdx + pdy*pdy) < ( (self.size + 8) * (self.size + 8) ) then
            self.state = "return"
        end

    elseif self.state == "return" then
        -- recompute anchor relative to (possibly moved) player and head back
        anchorX = (ctx.playerX - ctx.roomX) + math.cos(self.idleAngle) * self.idleDist
        anchorY = (ctx.playerY - ctx.roomY) + math.sin(self.idleAngle) * self.idleDist

        local dx = anchorX - myX
        local dy = anchorY - myY
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > 0.1 then
            local step = math.min(self.returnSpeed * dt, dist)
            myX = myX + (dx / dist) * step
            myY = myY + (dy / dist) * step
        end

        if dist <= 4 then
            self.state = "idle"
        end
    end

    -- write back relative position and clamp to room
    self.relX = math.max(0, math.min(1, myX / ctx.roomWidth))
    self.relY = math.max(0, math.min(1, myY / ctx.roomHeight))
end

function Pigeon:draw(ctx)
    -- position absolue dans la salle
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    -- Change color based on state
    if self.state == "dash" then
        love.graphics.setColor(1, 0.2, 0.2)  -- red when dashing
    else
        love.graphics.setColor(0.7, 0.4, 0.8)
    end
    love.graphics.circle("fill", x, y, self.size * (ctx.scale or 1))

    -- Draw dash trigger zone visualization (if debugging)
    if ctx.debugMode then
        love.graphics.setColor(1, 0, 0, 0.2)
        love.graphics.circle("line", x, y, self.dashTriggerDist)
    end
end

return Pigeon
