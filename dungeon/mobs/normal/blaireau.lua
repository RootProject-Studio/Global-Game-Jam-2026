local Mob = require("dungeon.mobs.mob")
local Blaireau = setmetatable({}, {__index = Mob})
Blaireau.__index = Blaireau

function Blaireau:new(data)
    data.category = "normal"
    data.subtype = "Blaireau"
    data.speed = 60
    data.size = 30           -- hitbox (collision)
    data.maxHP = data.maxHP or 300
    data.damage = data.damage or 5

    local m = Mob.new(self, data)
    m.attackCooldown = 0.5
    m.attackTimer = 0
    m.dir = math.random() * 2 * math.pi

    -- Animation
    m.images = {
        love.graphics.newImage("dungeon/mobs/normal/assets/blaireau.png"),
        love.graphics.newImage("dungeon/mobs/normal/assets/blaireau2.png")
    }
    m.currentFrame = 1
    m.frameTime = 0
    m.frameDelay = 0.2      -- changer tous les 0.2s

    -- Taille visuelle du sprite (en pixels)
    m.visualSize = 240
    m.baseVisualSize = m.visualSize

    return m
end

function Blaireau:applyScale(scale)
    if not scale then return end
    if Mob.applyScale then
        Mob.applyScale(self, scale)
    end
    if self.baseVisualSize then
        self.visualSize = self.baseVisualSize * scale
    end
end

function Blaireau:update(dt, ctx)
    local player = ctx.player
    if not player or not ctx.playerX or not ctx.playerY then return end

    -- Position en pixels
    local myX = self.relX * ctx.roomWidth
    local myY = self.relY * ctx.roomHeight

    local playerX = ctx.playerX - ctx.roomX
    local playerY = ctx.playerY - ctx.roomY

    local dx = playerX - myX
    local dy = playerY - myY
    local dist = math.sqrt(dx*dx + dy*dy)

    -- Déplacement vers le joueur
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

    -- Attaque
    self.attackTimer = (self.attackTimer or 0) + dt
    local hitboxMultiplier = 2
    local attackRange = (self.size + (player.size or 8)) * hitboxMultiplier
    if dist <= attackRange then
        if self.attackTimer >= (self.attackCooldown or 0.5) and (not player.hitCooldown or player.hitCooldown <= 0) then
            player.hp = math.max(0, player.hp - (self.damage or 1))
            player.hitCooldown = 0.5
            self.attackTimer = 0
        end
    end

    -- Animation
    self.frameTime = self.frameTime + dt
    if self.frameTime >= self.frameDelay then
        self.frameTime = 0
        self.currentFrame = self.currentFrame + 1
        if self.currentFrame > #self.images then
            self.currentFrame = 1
        end
    end
end

function Blaireau:draw(ctx)
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    if self.images and self.images[self.currentFrame] then
        local img = self.images[self.currentFrame]
        local imgWidth = img:getWidth()
        local imgHeight = img:getHeight()

        -- Taille visuelle
        local scale = self.visualSize / math.max(imgWidth, imgHeight)

        -- Offset vertical pour centrer le sprite sur la hitbox
        local visualCenterOffset = self.visualSize * 0.15  -- ajuste si nécessaire

        love.graphics.setColor(1,1,1)
        love.graphics.draw(img, x, y + visualCenterOffset, 0, scale, scale, imgWidth/2, imgHeight/2)

        -- Barre de vie
        if self.maxHP > 1 then
            local barWidth = self.size * 2  -- hitbox * 2
            local barHeight = 6             -- pixels, fixe

            -- Positionner la barre juste au-dessus de la tête
            local barY = y + visualCenterOffset - (self.visualSize/2) + 30

            love.graphics.setColor(0,0,0)
            love.graphics.rectangle("fill", x - barWidth/2, barY, barWidth, barHeight)
            love.graphics.setColor(0,1,0)
            love.graphics.rectangle("fill", x - barWidth/2, barY, barWidth * (self.hp/self.maxHP), barHeight)
        end
    end
end



return Blaireau
