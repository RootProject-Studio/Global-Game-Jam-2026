-- states/game.lua
-- État du jeu principal

local GameState = {}
local GameStateManager = require("gamestate")
local DungeonGenerator = require("dungeon.generator")
local Pedro            = require("dungeon.mobs.player.pedro")
local Cyclope          = require("dungeon.masks.cyclope")

function GameState:enter()

    self.player = Pedro:new()
    local cyclope = Cyclope:new()
    self.player:equipMask(cyclope)

    -- Générer un nouveau donjon
    self.generator = DungeonGenerator:new()
    self.dungeon = self.generator:generate()
    self.generator:populateRooms()
    
    -- Trouver la salle de départ
    self.currentRoom = nil
    for _, room in ipairs(self.dungeon) do
        if room.type == DungeonGenerator.ROOM_TYPES.START then
            self.currentRoom = room
            break
        end
    end
    
    -- Valeurs de base (résolution 800x600)
    self.baseWidth = 800
    self.baseHeight = 600
    self.baseRoomX = 50
    self.baseRoomY = 50
    self.baseRoomWidth = 700
    self.baseRoomHeight = 500
    self.basePlayerX = 400
    self.basePlayerY = 300
    self.basePlayerSpeed = 400
    self.basePlayerSize = 20
    
    -- Mode de visualisation
    self.showMap = true
    self.baseMapScale = 40
    self.baseMapOffsetX = 50
    self.baseMapOffsetY = 50
    
    -- Mode debugging
    self.debugMode = false
    
    self:updateLayout()
end

function GameState:updateLayout()
    -- Utiliser l'échelle minimale pour éviter un zoom excessif
    -- et garder une taille de jeu raisonnable
    local scale = math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    
    -- Dimensions de la salle
    local roomWidth = self.baseRoomWidth * scale
    local roomHeight = self.baseRoomHeight * scale
    self.roomWidth = roomWidth
    self.roomHeight = roomHeight
    
    -- Centrer le jeu horizontalement et verticalement
    self.roomX = (_G.gameConfig.windowWidth - roomWidth) / 2
    self.roomY = (_G.gameConfig.windowHeight - roomHeight) / 2
    
    -- Position et vitesse du joueur (relative au centre)
    -- Garder les positions relatives à la salle
    -- self.player.x = self.roomX + (self.basePlayerX - self.baseRoomX) * scale
    -- self.player.y = self.roomY + (self.basePlayerY - self.baseRoomY) * scale
    -- self.player.speed = self.basePlayerSpeed * scale -- Adapter la vitesse à l'échelle
    -- self.player.size = self.basePlayerSize * scale
    
    -- Carte (échelle réduite pour rester proportionnelle)
    self.mapScale = self.baseMapScale * math.min(scale, 0.8) -- Limiter l'agrandissement de la carte
    self.mapOffsetX = 20 * scale  -- Marges réduites
    self.mapOffsetY = 20 * scale
end

function GameState:update(dt)
    -- Update du joueur (Pedro gère son propre mouvement)
    if self.player then
        -- Créer le contexte de la salle pour Pedro
        local roomContext = {
            roomX = self.roomX,
            roomY = self.roomY,
            roomWidth = self.roomWidth,
            roomHeight = self.roomHeight
        }
        self.player:update(dt, roomContext)
    end
    
    -- Vérifier les transitions de salle via les portes
    local doorWidth = 60 * _G.gameConfig.scaleX
    local doorThreshold = 30 * _G.gameConfig.scaleX
    local playerX = self.player.x
    local playerY = self.player.y
    
    -- Porte du haut
    if self.currentRoom.doors.top and playerY < self.roomY + doorThreshold then
        local centerX = self.roomX + self.roomWidth / 2
        if playerX > centerX - doorWidth/2 and playerX < centerX + doorWidth/2 then
            self:changeRoom(0, -1)
            self.player.y = self.roomY + self.roomHeight * 0.85
            return
        end
    end
    
    -- Porte du bas
    if self.currentRoom.doors.bottom and playerY > self.roomY + self.roomHeight - doorThreshold then
        local centerX = self.roomX + self.roomWidth / 2
        if playerX > centerX - doorWidth/2 and playerX < centerX + doorWidth/2 then
            self:changeRoom(0, 1)
            self.player.y = self.roomY + self.roomHeight * 0.15
            return
        end
    end
    
    -- Porte de gauche
    if self.currentRoom.doors.left and playerX < self.roomX + doorThreshold then
        local centerY = self.roomY + self.roomHeight / 2
        if playerY > centerY - doorWidth/2 and playerY < centerY + doorWidth/2 then
            self:changeRoom(-1, 0)
            self.player.x = self.roomX + self.roomWidth * 0.85
            return
        end
    end
    
    -- Porte de droite
    if self.currentRoom.doors.right and playerX > self.roomX + self.roomWidth - doorThreshold then
        local centerY = self.roomY + self.roomHeight / 2
        if playerY > centerY - doorWidth/2 and playerY < centerY + doorWidth/2 then
            self:changeRoom(1, 0)
            self.player.x = self.roomX + self.roomWidth * 0.15
            return
        end
    end
    
    -- Limiter le joueur aux bords de la salle
    local margin = self.player.size
    self.player.x = math.max(self.roomX + margin, math.min(self.roomX + self.roomWidth - margin, self.player.x))
    self.player.y = math.max(self.roomY + margin, math.min(self.roomY + self.roomHeight - margin, self.player.y))
    -- Vérifier les collisions des projectiles avec les ennemis (système générique)
    if self.currentRoom and self.currentRoom.mobs then
        self.player:checkProjectileCollisions(self.currentRoom.mobs)
    end

    -- Update des mobs
    self:updateMobs(dt)
end

function GameState:draw()
    love.graphics.clear(0.15, 0.1, 0.1)
    
    -- Dessiner la salle actuelle
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", self.roomX, self.roomY, self.roomWidth, self.roomHeight)
    
    if self.player then
        self.player:draw()
    end

        -- Dessiner les mobs de la salle
    if self.currentRoom.mobs then
        for _, mob in ipairs(self.currentRoom.mobs) do
            mob:draw({
                roomX = self.roomX,
                roomY = self.roomY,
                roomWidth = self.roomWidth,
                roomHeight = self.roomHeight
            })
        end
    end
    
    -- Dessiner les portes
    self:drawDoors()
    
    -- Dessiner la mini-map si activée
    if self.showMap then
        self:drawMiniMap()
    end
    
    -- Affichage du debugging si activé
    if self.debugMode then
        self:drawDebugInfo()
    end



    -- Instructions en bas
    love.graphics.setColor(1, 1, 1)
    local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    local fontSize = math.max(12, 12 * scale)
    love.graphics.setNewFont(fontSize)
    local padding = 20 * scale
    love.graphics.print("D: debug | M: carte | R: regener | Echap: menu", padding, _G.gameConfig.windowHeight - padding - 10)
end

function GameState:drawDebugInfo()
    love.graphics.setColor(1, 1, 1)
    local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    local fontSize = math.max(12, 12 * scale)
    love.graphics.setNewFont(fontSize)
    
    local padding = 20 * scale      -- marge depuis le bord
    local lineHeight = 20 * scale   -- espace entre lignes
    local startX = padding
    local startY = padding
    
    local line = 0  -- compteur de lignes

    -- En-tête
    love.graphics.print("=== DEBUGGING ===", startX, startY + lineHeight * line)
    line = line + 1

    -- Type de salle
    love.graphics.print("Type de salle: " .. self.currentRoom.type, startX, startY + lineHeight * line)
    line = line + 1

    -- Position grille
    love.graphics.print(
        "Position grille: (" .. self.currentRoom.gridX .. ", " .. self.currentRoom.gridY .. ")",
        startX,
        startY + lineHeight * line
    )
    line = line + 1

    -- Position joueur
    love.graphics.print(
        "Position joueur: (" .. math.floor(self.player.x) .. ", " .. math.floor(self.player.y) .. ")",
        startX,
        startY + lineHeight * line
    )
    line = line + 1

    -- Vitesse joueur
    love.graphics.print(
        "Vitesse: (" .. math.floor(self.player.vx) .. ", " .. math.floor(self.player.vy) .. ")",
        startX,
        startY + lineHeight * line
    )
    line = line + 1

    -- PV joueur
    love.graphics.print(
        "PV joueur: " .. (self.player.hp or 0) .. " / " .. (self.player.maxHp or 0),
        startX,
        startY + lineHeight * line
    )
    line = line + 1

    -- Taille fenêtre
    love.graphics.print(
        "Taille fenêtre: " .. _G.gameConfig.windowWidth .. "x" .. _G.gameConfig.windowHeight,
        startX,
        startY + lineHeight * line
    )
    line = line + 1

    -- Echelle
    love.graphics.print("Echelle: " .. string.format("%.2f", scale), startX, startY + lineHeight * line)
    line = line + 1

    -- Portes disponibles
    local doorsText = "Portes: "
    if self.currentRoom.doors.top then doorsText = doorsText .. "H " end
    if self.currentRoom.doors.bottom then doorsText = doorsText .. "B " end
    if self.currentRoom.doors.left then doorsText = doorsText .. "G " end
    if self.currentRoom.doors.right then doorsText = doorsText .. "D " end
    if doorsText == "Portes: " then doorsText = doorsText .. "Aucune" end
    love.graphics.print(doorsText, startX, startY + lineHeight * line)
    line = line + 1

    -- Liste des mobs
    if self.currentRoom.mobs and #self.currentRoom.mobs > 0 then
        local mobsText = "Mobs: "
        for i, mob in ipairs(self.currentRoom.mobs) do
            mobsText = mobsText .. (mob.subtype or mob.type or "unknown")
            if i < #self.currentRoom.mobs then
                mobsText = mobsText .. ", "
            end
        end
        love.graphics.print(mobsText, startX, startY + lineHeight * line)
    else
        love.graphics.print("Mobs: Aucun", startX, startY + lineHeight * line)
    end
end


function GameState:drawDoors()
    local doorWidth = 60 * _G.gameConfig.scaleX
    local doorHeight = 20 * _G.gameConfig.scaleY
    local centerRoomX = self.roomX + self.roomWidth / 2
    local centerRoomY = self.roomY + self.roomHeight / 2
    
    -- Porte du haut
    if self.currentRoom.doors.top then
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.rectangle("fill", centerRoomX - doorWidth/2, self.roomY, doorWidth, doorHeight)
        -- Bordure de la porte
        love.graphics.setColor(0.5, 0.4, 0.3)
        love.graphics.rectangle("line", centerRoomX - doorWidth/2, self.roomY, doorWidth, doorHeight)
    end
    
    -- Porte de droite
    if self.currentRoom.doors.right then
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.rectangle("fill", self.roomX + self.roomWidth - doorHeight, centerRoomY - doorWidth/2, doorHeight, doorWidth)
        -- Bordure de la porte
        love.graphics.setColor(0.5, 0.4, 0.3)
        love.graphics.rectangle("line", self.roomX + self.roomWidth - doorHeight, centerRoomY - doorWidth/2, doorHeight, doorWidth)
    end
    
    -- Porte du bas
    if self.currentRoom.doors.bottom then
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.rectangle("fill", centerRoomX - doorWidth/2, self.roomY + self.roomHeight - doorHeight, doorWidth, doorHeight)
        -- Bordure de la porte
        love.graphics.setColor(0.5, 0.4, 0.3)
        love.graphics.rectangle("line", centerRoomX - doorWidth/2, self.roomY + self.roomHeight - doorHeight, doorWidth, doorHeight)
    end
    
    -- Porte de gauche
    if self.currentRoom.doors.left then
        love.graphics.setColor(0.1, 0.1, 0.1)
        love.graphics.rectangle("fill", self.roomX, centerRoomY - doorWidth/2, doorHeight, doorWidth)
        -- Bordure de la porte
        love.graphics.setColor(0.5, 0.4, 0.3)
        love.graphics.rectangle("line", self.roomX, centerRoomY - doorWidth/2, doorHeight, doorWidth)
    end
end

function GameState:drawMiniMap()
    -- Limiter la taille de la mini-map à 25% de la largeur et hauteur maximum
    local maxMapWidth = math.min(_G.gameConfig.windowWidth * 0.25, 250)
    local maxMapHeight = math.min(_G.gameConfig.windowHeight * 0.25, 250)
    
    local mapX = _G.gameConfig.windowWidth - maxMapWidth - 20
    local mapY = 20
    local mapWidth = maxMapWidth
    local mapHeight = maxMapHeight
    local roomSize = self.mapScale * 0.8
    local roomSpacing = self.mapScale
    
    -- Fond de la carte
    love.graphics.setColor(0.05, 0.05, 0.08, 0.9)
    love.graphics.rectangle("fill", mapX, mapY, mapWidth, mapHeight, 5, 5)
    
    -- Titre
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(math.max(10, 10 * _G.gameConfig.scaleX))
    love.graphics.print("CARTE", mapX + 10, mapY + 5)
    
    -- Calculer le centre de la carte
    local centerX = mapX + mapWidth / 2
    local centerY = mapY + mapHeight / 2
    
    -- Dessiner les salles
    for _, room in ipairs(self.dungeon) do
        local rx = centerX + (room.gridX - self.currentRoom.gridX) * roomSpacing - roomSize/2
        local ry = centerY + (room.gridY - self.currentRoom.gridY) * roomSpacing - roomSize/2
        
        -- Vérifier si dans les limites de la carte
        if rx >= mapX and rx + roomSize <= mapX + mapWidth and
           ry >= mapY and ry + roomSize <= mapY + mapHeight then
            
            -- Couleur selon le type de salle
            if room == self.currentRoom then
                love.graphics.setColor(1, 1, 0) -- Jaune pour la salle actuelle
            elseif room.type == DungeonGenerator.ROOM_TYPES.START then
                love.graphics.setColor(0.5, 0.8, 0.5) -- Vert pour le départ
            elseif room.type == DungeonGenerator.ROOM_TYPES.BOSS then
                love.graphics.setColor(0.9, 0.2, 0.2) -- Rouge pour le boss
            elseif room.type == DungeonGenerator.ROOM_TYPES.SHOP then
                love.graphics.setColor(0.5, 0.5, 0.9) -- Bleu pour la boutique
            else
                love.graphics.setColor(0.6, 0.6, 0.6) -- Gris pour les salles normales
            end
            
            love.graphics.rectangle("fill", rx, ry, roomSize, roomSize, 2, 2)
            
            -- Dessiner les connexions
            love.graphics.setColor(0.4, 0.4, 0.4)
            local lineWidth = 2
            
            if room.doors.top then
                love.graphics.rectangle("fill", rx + roomSize/2 - lineWidth/2, ry - roomSpacing + roomSize, lineWidth, roomSpacing - roomSize)
            end
            if room.doors.right then
                love.graphics.rectangle("fill", rx + roomSize, ry + roomSize/2 - lineWidth/2, roomSpacing - roomSize, lineWidth)
            end
            if room.doors.bottom then
                love.graphics.rectangle("fill", rx + roomSize/2 - lineWidth/2, ry + roomSize, lineWidth, roomSpacing - roomSize)
            end
            if room.doors.left then
                love.graphics.rectangle("fill", rx - roomSpacing + roomSize, ry + roomSize/2 - lineWidth/2, roomSpacing - roomSize, lineWidth)
            end
        end
    end
end

function GameState:changeRoom(dx, dy)
    -- Trouver la salle adjacente
    local newGridX = self.currentRoom.gridX + dx
    local newGridY = self.currentRoom.gridY + dy
    
    -- Chercher la salle correspondante dans le donjon
    for _, room in ipairs(self.dungeon) do
        if room.gridX == newGridX and room.gridY == newGridY then
            self.currentRoom = room
            return
        end
    end
end

function GameState:keypressed(key)
    if key == "escape" then
        GameStateManager:setState("menu")
    elseif key == "m" then
        self.showMap = not self.showMap
    elseif key == "p" then
        self.debugMode = not self.debugMode
    elseif key == "r" then
        -- Régénérer le donjon
        self:enter()
    end
end

function GameState:exit()
end

-- Gestion du redimensionnement
function GameState:onResize()
    self:updateLayout()
end

-- Mettre à jour les mobs de la salle actuelle
function GameState:updateMobs(dt)
    if not self.currentRoom.mobs then return end

    local roomX = self.roomX
    local roomY = self.roomY
    local roomW = self.roomWidth
    local roomH = self.roomHeight
    local scale = _G.gameConfig.scaleX or 1

    -- 1) Update each mob
    for _, mob in ipairs(self.currentRoom.mobs) do
        mob:update(dt, {
            roomX = roomX,
            roomY = roomY,
            roomWidth = roomW,
            roomHeight = roomH,
            playerX = self.player.x,
            playerY = self.player.y,
            scale = scale,
            player = self.player
        })
    end

    -- 2) Build absolute positions and radii
    local mobCount = #self.currentRoom.mobs
    local abs = {}
    for i, mob in ipairs(self.currentRoom.mobs) do
        local mx = roomX + mob.relX * roomW
        local my = roomY + mob.relY * roomH
        local mr = (mob.size or 10) * scale
        abs[i] = {mob = mob, x = mx, y = my, r = mr}
    end

    -- 3) Resolve mob↔mob collisions (simple push-apart)
    for i = 1, mobCount do
        for j = i+1, mobCount do
            local a = abs[i]
            local b = abs[j]
            local dx = a.x - b.x
            local dy = a.y - b.y
            local dist2 = dx*dx + dy*dy
            local minDist = a.r + b.r
            if dist2 < (minDist * minDist) then
                local dist = math.sqrt(dist2)
                if dist == 0 then
                    dx = 0.01; dy = 0.01; dist = math.sqrt(dx*dx + dy*dy)
                end
                local overlap = minDist - dist
                -- Normalized direction from b to a
                local nx = dx / dist
                local ny = dy / dist
                -- Push each by half the overlap
                local pushAX = nx * (overlap * 0.5)
                local pushAY = ny * (overlap * 0.5)
                local pushBX = -nx * (overlap * 0.5)
                local pushBY = -ny * (overlap * 0.5)

                -- Apply to absolute positions
                a.x = a.x + pushAX
                a.y = a.y + pushAY
                b.x = b.x + pushBX
                b.y = b.y + pushBY
            end
        end
    end

    -- 4) Write back adjusted mob rel positions and clamp to room
    for i, info in ipairs(abs) do
        local m = info.mob
        m.relX = math.max(0, math.min(1, (info.x - roomX) / roomW))
        m.relY = math.max(0, math.min(1, (info.y - roomY) / roomH))
    end

    -- 5) Resolve mob↔player collisions (push player away and keep player inside room)
    for _, info in ipairs(abs) do
        local mx = info.x
        local my = info.y
        local mr = info.r
        local px = self.player.x
        local py = self.player.y
        local pr = self.player.size or 8

        local dx = px - mx
        local dy = py - my
        local dist2 = dx*dx + dy*dy
        local minDist = pr + mr
        if dist2 < (minDist * minDist) then
            local dist = math.sqrt(dist2)
            if dist == 0 then
                dx = 0.01; dy = 0.01; dist = math.sqrt(dx*dx + dy*dy)
            end
            local overlap = minDist - dist
            local nx = dx / dist
            local ny = dy / dist

            -- Push player away by the overlap (prefer moving player)
            local pushPX = nx * overlap
            local pushPY = ny * overlap
            self.player.x = self.player.x + pushPX
            self.player.y = self.player.y + pushPY

            -- Clamp player inside room
            local margin = self.player.size
            self.player.x = math.max(roomX + margin, math.min(roomX + roomW - margin, self.player.x))
            self.player.y = math.max(roomY + margin, math.min(roomY + roomH - margin, self.player.y))

            -- Optionally, nudge mob slightly away as well to avoid sticking
            local mob = info.mob
            mob.relX = math.max(0, math.min(1, (mx - nx * (overlap * 0.25) - roomX) / roomW))
            mob.relY = math.max(0, math.min(1, (my - ny * (overlap * 0.25) - roomY) / roomH))
        end
    end
end



return GameState