local Mob = require("dungeon.mobs.mob")
local Rat = setmetatable({}, {__index = Mob})
Rat.__index = Rat

function Rat:new(data)
    data.category = "normal"
    data.subtype = "rat"
    data.speed = 60          -- pixels par seconde
    data.size = 14           -- rayon du Rat
    data.maxHP = data.maxHP or 100  -- PV max
    data.damage = data.damage or 5  -- dégâts infligés au joueur
    data.dropChance = 1
    

    local m = Mob.new(self, data)
    m.attackCooldown = 0.5   -- temps entre deux attaques
    m.attackTimer = 0         -- timer interne pour l'attaque

    m.dir = math.random() * 2 * math.pi  -- direction aléatoire

    m.currentFrame = 1
    m.frameTime = 0
    m.frameDelay = 0.1

    m.image = {
        love.graphics.newImage("dungeon/mobs/normal/assets/rat1.png"),
        love.graphics.newImage("dungeon/mobs/normal/assets/rat2.png")
    }

    return m
end

function Rat:update(dt, ctx)
    local player = ctx.player
    if not player or not ctx.playerX or not ctx.playerY then return end

    isMoving = false

    -- Position du Rat en pixels
    local myX = self.relX * ctx.roomWidth
    local myY = self.relY * ctx.roomHeight

    -- Position du joueur en pixels
    local playerX = ctx.playerX - ctx.roomX
    local playerY = ctx.playerY - ctx.roomY

    local dx = playerX - myX
    local dy = playerY - myY
    local dist = math.sqrt(dx*dx + dy*dy)

    -- Déplacement du Rat vers le joueur
    if dist > 0 then
        local vx = dx / dist
        local vy = dy / dist

        local move_px = self.speed * dt
        self.relX = self.relX + (vx * move_px / ctx.roomWidth)
        self.relY = self.relY + (vy * move_px / ctx.roomHeight)

        isMoving = true
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



function Rat:draw(ctx)
    -- position absolue dans la salle
    local scale = ctx.scale or 1
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    -- love.graphics.setColor(0.3, 0.8, 0.8)
    -- love.graphics.circle("fill", x, y, self.size)

    if self.image and self.image[self.currentFrame] then
        love.graphics.setColor(1, 1, 1)
        local img = self.image[self.currentFrame]
        local imgWidth = img:getWidth()
        local imgHeight = img:getHeight()
        local scaleX = (self.size * 11) / imgWidth
        local scaleY = (self.size * 11) / imgHeight
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
end

return Rat
