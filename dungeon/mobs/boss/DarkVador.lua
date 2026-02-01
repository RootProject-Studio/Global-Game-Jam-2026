local Mob = require("dungeon.mobs.mob")
local DarkVador = setmetatable({}, Mob)
DarkVador.__index = DarkVador

function DarkVador:new(data)
    data.category = "boss"
    data.subtype = "darkvador"
    data.speed = 0
    data.size = 40
    data.maxHP = data.maxHP or 600  -- PV max

    local m = Mob.new(self, data)


    -- Position initiale → coin choisi aléatoirement
    m.corners = {
        {0.1, 0.1}, {0.9, 0.1}, {0.1, 0.9}, {0.9, 0.9},
    }
    m.relX = 0.5
    m.relY = 0.5
    m.targetCorner = nil

    m.moveSpeed = 0.25

    -- Pattern d'attaque
    m.projectiles = {}
    m.state = "moving"     -- moving | attacking
    m.waveCount = 0 
    m.waveMax = 5
    m.waveCooldown = 0
    m.waveInterval = 2 + math.random() -- 2 à 3 sec

    m.currentFrame = 1
    m.frameTime = 0
    m.frameDelay = 0.1

    m.image = {
        love.graphics.newImage("dungeon/mobs/boss/assets/dodo1.png"),
        love.graphics.newImage("dungeon/mobs/boss/assets/dodo2.png")
    }

    return m
end

-- Mise à jour
function DarkVador:update(dt, ctx)
    if not self.projectiles then self.projectiles = {} end

    isMoving = false

    if self.state == "moving" then
        -- déplacement vers coin
            isMoving = true
        if not self.targetCorner then
            local choices = {}
            for _, c in ipairs(self.corners) do
                if c[1] ~= self.relX or c[2] ~= self.relY then
                    table.insert(choices, c)
                end
            end
            self.targetCorner = choices[math.random(#choices)]
        end

        local dirX = self.targetCorner[1] - self.relX
        local dirY = self.targetCorner[2] - self.relY
        local dist = math.sqrt(dirX^2 + dirY^2)
        if dist > 0 then
            self.relX = self.relX + (dirX / dist) * self.moveSpeed * dt
            self.relY = self.relY + (dirY / dist) * self.moveSpeed * dt
        end

        if dist < 0.01 then
            self.state = "attacking"
            self.waveCount = 0
            self.waveCooldown = 1 -- pause avant la première vague
        end

    elseif self.state == "attacking" then
        self.waveCooldown = self.waveCooldown - dt
        if self.waveCooldown <= 0 and self.waveCount < self.waveMax then
            -- Lancer seulement 1-2 barres par vague
            local barsThisWave = math.random(1,2)
            self:launchPattern(barsThisWave)
            self.waveCount = self.waveCount + 1
            -- Intervalle plus long entre vagues
            self.waveCooldown = 3 + math.random() -- 3 à 4 sec
        end

        if self.waveCount >= self.waveMax then
            self.state = "moving"
            self.targetCorner = nil
        end
    end

    -- Mise à jour des projectiles

    local margin = 0.05  -- 5% de la salle avant le bord pour disparaître

    for i = #self.projectiles, 1, -1 do
        local p = self.projectiles[i]

        -- Mettre à jour position
        p.relX = p.relX + p.dx * dt
        p.relY = p.relY + p.dy * dt

        -- Supprimer légèrement avant le bord
        if p.orientation == 1 then          -- gauche → droite (verticale)
            if p.relX - p.size/2 > 1 - margin then
                table.remove(self.projectiles, i)
            end
        elseif p.orientation == 2 then      -- droite → gauche
            if p.relX + p.size/2 < 0 + margin then
                table.remove(self.projectiles, i)
            end
        elseif p.orientation == 3 then      -- haut → bas (horizontale)
            if p.relY - p.size/2 > 1 - margin then
                table.remove(self.projectiles, i)
            end
        elseif p.orientation == 4 then      -- bas → haut
            if p.relY + p.size/2 < 0 + margin then
                table.remove(self.projectiles, i)
            end
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

    if ctx.player then
        self:checkProjectilesCollision(ctx.player, ctx)
    end



end

-- Lance 1 à 3 barres par vague
function DarkVador:launchPattern(barCount)
    for i = 1, barCount do
        local orientation = math.random(4)
        local color = math.random() > 0.5 and {1,0,0} or {0,0,1}
        local speed = 0.3

        local proj = {dx=0, dy=0, relX=0, relY=0, size=0.05, color=color, orientation=orientation, damage=25}

        if orientation == 3 then -- haut→bas
            proj.relX = 0
            proj.relY = 0
            proj.dx = 0
            proj.dy = speed
            proj.lengthX = 1
            proj.lengthY = proj.size
        elseif orientation == 4 then -- bas→haut
            proj.relX = 0
            proj.relY = 1
            proj.dx = 0
            proj.dy = -speed
            proj.lengthX = 1
            proj.lengthY = proj.size
        elseif orientation == 1 then -- gauche→droite
            proj.relX = 0
            proj.relY = 0
            proj.dx = speed
            proj.dy = 0
            proj.lengthX = proj.size
            proj.lengthY = 1
        elseif orientation == 2 then -- droite→gauche
            proj.relX = 1
            proj.relY = 0
            proj.dx = -speed
            proj.dy = 0
            proj.lengthX = proj.size
            proj.lengthY = 1
        end

        table.insert(self.projectiles, proj)
    end
end

-- Vérifie si une barre touche le joueur et applique les dégâts
function DarkVador:checkProjectilesCollision(player, ctx)
    local isMoving = math.abs(player.vx) > 0.1 or math.abs(player.vy) > 0.1

    for _, bar in ipairs(self.projectiles) do
        -- Coordonnées absolues de la barre
        local bx, by, bw, bh = 0, 0, 0, 0
        if bar.orientation == 1 or bar.orientation == 2 then
            -- vertical
            bw = bar.size * ctx.roomWidth
            bh = ctx.roomHeight
            bx = ctx.roomX + bar.relX * ctx.roomWidth - bw/2
            by = ctx.roomY
        else
            -- horizontal
            bw = ctx.roomWidth
            bh = bar.size * ctx.roomHeight
            bx = ctx.roomX
            by = ctx.roomY + bar.relY * ctx.roomHeight - bh/2
        end

        -- Collision ellipse vs rectangle
        local px, py = player.x, player.y
        local rx, ry = player.hitboxRadiusX, player.hitboxRadiusY
        local closestX = math.max(bx, math.min(px, bx + bw))
        local closestY = math.max(by, math.min(py, by + bh))
        local dx = (closestX - px) / rx
        local dy = (closestY - py) / ry

        if (dx*dx + dy*dy) <= 1 then
            -- Vérifier couleur et mouvement
            local canDamage = true
            if bar.color[1] == 1 and bar.color[2] == 0 and bar.color[3] == 0 then
                -- barre rouge → pas de dégâts si joueur bouge
                if isMoving then canDamage = false end
            elseif bar.color[1] == 0 and bar.color[2] == 0 and bar.color[3] == 1 then
                -- barre bleue → pas de dégâts si joueur immobile
                if not isMoving then canDamage = false end
            end

            -- Appliquer les dégâts si possible et pas sur cooldown
            if canDamage and (not player.hitCooldown or player.hitCooldown <= 0) then
                player.hp = math.max(0, player.hp - bar.damage)
                player.hitCooldown = 1
            end
        end
    end
end



-- Dessiner
function DarkVador:draw(ctx)
    local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    -- Boss
    -- love.graphics.setColor(0,0,0)
    -- love.graphics.circle("fill", x, y, self.size * scale)

    if self.image and self.image[self.currentFrame] then
        love.graphics.setColor(1, 1, 1)
        local img = self.image[self.currentFrame]
        local imgWidth = img:getWidth()
        local imgHeight = img:getHeight()
        local scaleX = (self.size * 5) / imgWidth
        local scaleY = (self.size * 5) / imgHeight
        love.graphics.draw(img, x, y, 0, scaleX, scaleY, imgWidth/2, imgHeight/2)
    end

    -- Projectiles = barres
    for _, p in ipairs(self.projectiles) do
        love.graphics.setColor(p.color)
        if p.orientation == 1 or p.orientation == 2 then -- vertical
            love.graphics.rectangle(
                "fill",
                ctx.roomX + p.relX * ctx.roomWidth - (p.size*ctx.roomWidth/2),
                ctx.roomY + p.relY * ctx.roomHeight,
                p.size * ctx.roomWidth,
                ctx.roomHeight
            )
        else -- horizontal
            love.graphics.rectangle(
                "fill",
                ctx.roomX + p.relX * ctx.roomWidth,
                ctx.roomY + p.relY * ctx.roomHeight - (p.size*ctx.roomHeight/2),
                ctx.roomWidth,
                p.size * ctx.roomHeight
            )
        end
    end

    -- Barre de vie du boss
    if self.maxHP and self.hp then
        local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
        local margin = 20 * scale
        local maxWidth = 400 * scale          -- largeur max de la barre
        local height = 20 * scale
        local x0 = (_G.gameConfig.windowWidth - maxWidth) / 2  -- centrer horizontalement
        local y0 = margin

        -- fond rouge
        love.graphics.setColor(0.5,0,0)
        love.graphics.rectangle("fill", x0, y0, maxWidth, height)

        -- vie verte proportionnelle
        love.graphics.setColor(0,1,0)
        love.graphics.rectangle("fill", x0, y0, maxWidth * (self.hp/self.maxHP), height)

        -- contour noir
        love.graphics.setColor(0,0,0)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", x0, y0, maxWidth, height)
    end
end

return DarkVador
