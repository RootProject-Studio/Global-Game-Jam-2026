local Mob = require("dungeon.mobs.mob")

local Pigeon = setmetatable({}, { __index = Mob })
Pigeon.__index = Pigeon

function Pigeon:new(data)
    data = data or {}

    data.category = "normal"
    data.subtype  = "pigeon"
    data.size     = data.size or 14
    data.speed    = data.speed or 90
    data.maxHP = data.maxHP or 5  -- PV max

    local m = Mob.new(self, data)

    -- Cercles centrés sur le PLAYER
    m.attackRadius    = data.attackRadius    or 160 -- déclenche dash
    m.placementRadius = data.placementRadius or 130 -- distance de repositionnement
    m.placementTolerance = 12
    m.orbitSpeed = data.orbitSpeed or 0.6

    -- Dash
    m.dashSpeed = data.dashSpeed or 300
    m.dashTime  = data.dashTime  or 0.3
    m.dashTimer = 0
    m.damage = data.damage or 1


    -- Cooldown
    m.cooldownTime  = data.cooldownTime or 1.5
    m.cooldownTimer = 0

    m.dashDirX = 0
    m.dashDirY = 0

    m.state = "idle" -- idle | dash | cooldown

    m.currentFrame = 1
    m.frameTime = 0
    m.frameDelay = 0.1

    m.image = {
        love.graphics.newImage("dungeon/mobs/normal/assets/pigeon1.png"),
        love.graphics.newImage("dungeon/mobs/normal/assets/pigeon2.png")
    }

    return m
end

----------------------------------------------------------------
-- UPDATE
----------------------------------------------------------------
function Pigeon:update(dt, ctx)
    if not ctx.playerX or not ctx.playerY then return end

    isMoving = false

    -- Positions absolues
    local myX = self.relX * ctx.roomWidth
    local myY = self.relY * ctx.roomHeight

    local playerX = ctx.playerX - ctx.roomX
    local playerY = ctx.playerY - ctx.roomY

    -- Vecteur PLAYER → PIGEON
    local dx = myX - playerX
    local dy = myY - playerY
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist == 0 then dist = 0.001 end

    ------------------------------------------------------------
    -- IDLE : attendre dans la zone, attaquer si trop proche
    ------------------------------------------------------------
    
    
    if self.state == "idle" then
        -- Si assez proche → attaquer
        if dist <= self.attackRadius then
            -- Vecteur normalisé vers le joueur
            local dirX = (playerX - myX) / dist
            local dirY = (playerY - myY) / dist

            local dashDistance = dist * 2  -- 50% plus loin
            self.dashDirX = dirX
            self.dashDirY = dirY
            self.dashTargetDistance = dashDistance

            self.dashTimer = 0
            self.state = "dash"
            goto finalize
        end

        -- Maintien autour du joueur
        local targetDist = self.placementRadius
        local tolerance  = self.placementTolerance

        local moveX, moveY = 0, 0

        -- Trop loin → se rapprocher
        if dist > targetDist + tolerance then
            moveX = -dx / dist
            moveY = -dy / dist

            isMoving = true

        -- Trop proche → s’éloigner
        elseif dist < targetDist - tolerance then
            moveX = dx / dist
            moveY = dy / dist

            isMoving = true

        -- Bonne distance → orbite
        else
            moveX = -dy / dist
            moveY = dx / dist

            isMoving = true
        end

        local speed = self.speed
        if dist >= targetDist - tolerance and dist <= targetDist + tolerance then
            speed = speed * self.orbitSpeed
        end

        myX = myX + moveX * speed * dt
        myY = myY + moveY * speed * dt

    ------------------------------------------------------------
    -- DASH
    ------------------------------------------------------------
    elseif self.state == "dash" then
        local move = self.dashSpeed * dt
        myX = myX + self.dashDirX * move
        myY = myY + self.dashDirY * move

        -- Appliquer les dégâts au joueur
        if ctx.player then
            local player = ctx.player

            -- Positions absolues du pigeon
            local absX = ctx.roomX + self.relX * ctx.roomWidth
            local absY = ctx.roomY + self.relY * ctx.roomHeight

            -- dx/dy vers le joueur
            local dx = ctx.player.x - absX
            local dy = ctx.player.y - absY

            local hitRadiusMultiplier = 1
            local rx = ctx.player.hitboxRadiusX + self.size * hitRadiusMultiplier
            local ry = ctx.player.hitboxRadiusY + self.size * hitRadiusMultiplier
            local distanceSquared = (dx*dx)/(rx*rx) + (dy*dy)/(ry*ry)

            if distanceSquared <= 1 then
                -- Collision détectée
                if not player.hitCooldown or player.hitCooldown <= 0 then
                    local damage = self.damage or 1
                    player.hp = math.max(0, player.hp - damage)
                    player.hitCooldown = 0.5  -- 1 seconde d'invincibilité
                end
            end
        end

        self.dashTimer = self.dashTimer + dt
        if self.dashTimer >= self.dashTime then
            self.cooldownTimer = 0
            self.state = "cooldown"
        end


    ------------------------------------------------------------
    -- COOLDOWN : se replacer hors du joueur
    ------------------------------------------------------------
    elseif self.state == "cooldown" then
        self.cooldownTimer = self.cooldownTimer + dt

        if dist < 0.001 then goto finalize end

        -- Si cooldown fini et joueur proche → dash
        if self.cooldownTimer >= self.cooldownTime and dist <= self.attackRadius then
            local dirX = (playerX - myX) / dist
            local dirY = (playerY - myY) / dist

            local dashDistance = dist * 1.5
            self.dashDirX = dirX
            self.dashDirY = dirY
            self.dashTargetDistance = dashDistance

            self.dashTimer = 0
            self.state = "dash"
            self.cooldownTimer = 0
            goto finalize
        end

        -- Sinon, s’éloigner si trop proche
        if dist < self.placementRadius then
            local fleeX = - (playerX - myX) / dist
            local fleeY = - (playerY - myY) / dist
            local move = self.speed * dt

            myX = myX + fleeX * move
            myY = myY + fleeY * move

            isMoving = true
        end

        if self.cooldownTimer >= self.cooldownTime and dist >= self.placementRadius then
            self.state = "idle"
        end
    end


    ::finalize::

    -- Clamp salle
    self.relX = math.max(0, math.min(1, myX / ctx.roomWidth))
    self.relY = math.max(0, math.min(1, myY / ctx.roomHeight))

    if isMoving then
        self.frameTime = self.frameTime + dt
        if self.frameTime >= self.frameDelay then
            self.frameTime = 0
            self.currentFrame = self.currentFrame + 1
            if self.currentFrame > #self.image then
                self.currentFrame = 1
            end
        end
    else
        self.frameTime = 0
        self.currentFrame = 1
    end
end

----------------------------------------------------------------
-- DRAW
----------------------------------------------------------------
function Pigeon:draw(ctx)
    local scale = ctx.scale or 1
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight


    if self.image and self.image[self.currentFrame] then
        love.graphics.setColor(1, 1, 1)
        local img = self.image[self.currentFrame]
        local imgWidth = img:getWidth()
        local imgHeight = img:getHeight()
        local scaleX = (self.size * 10) / imgWidth
        local scaleY = (self.size * 10) / imgHeight
        love.graphics.draw(img, x, y, 0, scaleX, scaleY, imgWidth/2, imgHeight/2)
    
        -- Barre de vie
        if self.maxHP > 1 then
            local barWidth = self.size * scale * 2
            local barHeight = 3 * scale
            local barY = y - (imgHeight * scaleY / 3) - 8

            love.graphics.rectangle("fill", x - barWidth/2, barY, barWidth, barHeight)
            love.graphics.setColor(0, 1, 0)
            love.graphics.rectangle("fill", x - barWidth/2, barY, barWidth * (self.hp/self.maxHP), barHeight)
        end
    
    end

    


    -- DEBUG : cercles centrés sur le player
    if ctx.debugMode and ctx.playerX and ctx.playerY then
        local px, py = ctx.playerX, ctx.playerY

        -- Zone d'attaque
        love.graphics.setColor(1, 0, 0, 0.25)
        love.graphics.circle("line", px, py, self.attackRadius)

        -- Zone de placement
        love.graphics.setColor(0, 1, 0, 0.25)
        love.graphics.circle("line", px, py, self.placementRadius)
    end

    -- DEBUG : hitbox dash centrée sur le pigeon
    if ctx.debugMode and self.state == "dash" then
        love.graphics.setColor(1, 0, 0, 0.3)
        local hitboxRadius = self.size * 3  -- multiplier pour agrandir
        love.graphics.circle("line", x, y, hitboxRadius)
    end

    if ctx.debugMode and ctx.player then
        local player = ctx.player
        local px, py = player.x, player.y

        -- Correspond exactement au calcul utilisé pour les dégâts
        local hitRadiusMultiplier = 1.5  -- même que dans update
        local rx = player.hitboxRadiusX + self.size * hitRadiusMultiplier
        local ry = player.hitboxRadiusY + self.size * hitRadiusMultiplier

        love.graphics.setColor(1, 0, 0, 0.3) -- rouge transparent
        love.graphics.ellipse("line", px, py, rx, ry)
    end



end



return Pigeon
