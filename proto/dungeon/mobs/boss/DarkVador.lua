local Mob = require("dungeon.mobs.mob")
local DarkVador = setmetatable({}, Mob)
DarkVador.__index = DarkVador

function DarkVador:new(data)
    data.category = "boss"
    data.subtype = "darkvador"
    data.speed = 0
    data.size = 40

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

    return m
end

-- Mise à jour
function DarkVador:update(dt, ctx)
    if not self.projectiles then self.projectiles = {} end

    if self.state == "moving" then
        -- déplacement vers coin
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




end

-- Lance 1 à 3 barres par vague
function DarkVador:launchPattern(barCount)
    for i = 1, barCount do
        local orientation = math.random(4)
        local color = math.random() > 0.5 and {1,0,0} or {0,0,1}
        local speed = 0.3

        local proj = {dx=0, dy=0, relX=0, relY=0, size=0.05, color=color, orientation=orientation}

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


-- Dessiner
function DarkVador:draw(ctx)
    local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    -- Boss
    love.graphics.setColor(0,0,0)
    love.graphics.circle("fill", x, y, self.size * scale)

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
end

return DarkVador
