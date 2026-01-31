-- states/game.lua
-- État du jeu principal

local GameState = {}
local GameStateManager = require("gamestate")
local DungeonGenerator = require("dungeon.generator")

function GameState:enter()
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
    self.basePlayerSpeed = 800
    self.basePlayerSize = 20
    
    -- Position du joueur (centre de la salle)
    self.player = {
        x = self.basePlayerX,
        y = self.basePlayerY,
        speed = self.basePlayerSpeed,
        size = self.basePlayerSize
    }
    
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
    self.player.x = self.roomX + (self.basePlayerX - self.baseRoomX) * scale
    self.player.y = self.roomY + (self.basePlayerY - self.baseRoomY) * scale
    self.player.speed = self.basePlayerSpeed * scale -- Adapter la vitesse à l'échelle
    self.player.size = self.basePlayerSize * scale
    
    -- Carte (échelle réduite pour rester proportionnelle)
    self.mapScale = self.baseMapScale * math.min(scale, 0.8) -- Limiter l'agrandissement de la carte
    self.mapOffsetX = 20 * scale  -- Marges réduites
    self.mapOffsetY = 20 * scale
end

function GameState:update(dt)
    -- Déplacement du joueur
    local keys = _G.gameConfig.keys
    
    local moveSpeed = self.player.speed * dt
    local newX = self.player.x
    local newY = self.player.y
    
    if love.keyboard.isDown(keys.up) then
        newY = newY - moveSpeed
    end
    if love.keyboard.isDown(keys.down) then
        newY = newY + moveSpeed
    end
    if love.keyboard.isDown(keys.left) then
        newX = newX - moveSpeed
    end
    if love.keyboard.isDown(keys.right) then
        newX = newX + moveSpeed
    end
    
    -- Vérifier les transitions de salle via les portes
    local doorWidth = 60 * _G.gameConfig.scaleX
    local doorThreshold = 30 * _G.gameConfig.scaleX
    
    -- Porte du haut
    if self.currentRoom.doors.top and newY < self.roomY + doorThreshold then
        local centerX = self.roomX + self.roomWidth / 2
        if newX > centerX - doorWidth/2 and newX < centerX + doorWidth/2 then
            self:changeRoom(0, -1)
            self.player.y = self.roomY + self.roomHeight * 0.85 -- Apparaît plus loin du bord en bas de la nouvelle salle
            return
        end
    end
    
    -- Porte du bas
    if self.currentRoom.doors.bottom and newY > self.roomY + self.roomHeight - doorThreshold then
        local centerX = self.roomX + self.roomWidth / 2
        if newX > centerX - doorWidth/2 and newX < centerX + doorWidth/2 then
            self:changeRoom(0, 1)
            self.player.y = self.roomY + self.roomHeight * 0.15 -- Apparaît plus loin du bord en haut de la nouvelle salle
            return
        end
    end
    
    -- Porte de gauche
    if self.currentRoom.doors.left and newX < self.roomX + doorThreshold then
        local centerY = self.roomY + self.roomHeight / 2
        if newY > centerY - doorWidth/2 and newY < centerY + doorWidth/2 then
            self:changeRoom(-1, 0)
            self.player.x = self.roomX + self.roomWidth * 0.85 -- Apparaît plus loin du bord à droite de la nouvelle salle
            return
        end
    end
    
    -- Porte de droite
    if self.currentRoom.doors.right and newX > self.roomX + self.roomWidth - doorThreshold then
        local centerY = self.roomY + self.roomHeight / 2
        if newY > centerY - doorWidth/2 and newY < centerY + doorWidth/2 then
            self:changeRoom(1, 0)
            self.player.x = self.roomX + self.roomWidth * 0.15 -- Apparaît plus loin du bord à gauche de la nouvelle salle
            return
        end
    end
    
    -- Limiter le joueur aux bords de la salle (avec les murs)
    local margin = self.player.size
    newX = math.max(self.roomX + margin, math.min(self.roomX + self.roomWidth - margin, newX))
    newY = math.max(self.roomY + margin, math.min(self.roomY + self.roomHeight - margin, newY))
    
    self.player.x = newX
    self.player.y = newY

    self:updateMobs(dt)

end

function GameState:draw()
    love.graphics.clear(0.15, 0.1, 0.1)
    
    -- Dessiner la salle actuelle
    love.graphics.setColor(0.2, 0.2, 0.25)
    love.graphics.rectangle("fill", self.roomX, self.roomY, self.roomWidth, self.roomHeight)
    

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
    
    -- Dessiner le joueur
    love.graphics.setColor(0.9, 0.8, 0.6)
    love.graphics.circle("fill", self.player.x, self.player.y, self.player.size)
    
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
    
    -- Espacement adapté à l'échelle
    local padding = 20 * scale  -- Espacement de départ
    local lineHeight = 20 * scale  -- Hauteur entre les lignes
    local startY = padding
    local startX = padding
    
    -- Affichage en haut à gauche
    love.graphics.print("=== DEBUGGING ===", startX, startY)
    love.graphics.print("Type de salle: " .. self.currentRoom.type, startX, startY + lineHeight * 1)
    love.graphics.print("Position grille: (" .. self.currentRoom.gridX .. ", " .. self.currentRoom.gridY .. ")", startX, startY + lineHeight * 2)
    love.graphics.print("Position joueur: (" .. math.floor(self.player.x) .. ", " .. math.floor(self.player.y) .. ")", startX, startY + lineHeight * 3)
    love.graphics.print("Taille fenetre: " .. _G.gameConfig.windowWidth .. "x" .. _G.gameConfig.windowHeight, startX, startY + lineHeight * 4)
    love.graphics.print("Echelle: " .. string.format("%.2f", scale), startX, startY + lineHeight * 5)
    
    -- Affichage des portes disponibles
    local doorsText = "Portes: "
    if self.currentRoom.doors.top then doorsText = doorsText .. "H " end
    if self.currentRoom.doors.bottom then doorsText = doorsText .. "B " end
    if self.currentRoom.doors.left then doorsText = doorsText .. "G " end
    if self.currentRoom.doors.right then doorsText = doorsText .. "D " end
    if doorsText == "Portes: " then doorsText = doorsText .. "Aucune" end
    love.graphics.print(doorsText, startX, startY + lineHeight * 6)

    -- Liste des mobs présents
    if self.currentRoom.mobs and #self.currentRoom.mobs > 0 then
        local mobsText = "Mobs: "
        for i, mob in ipairs(self.currentRoom.mobs) do
            mobsText = mobsText .. (mob.subtype or mob.type or "unknown")
            if i < #self.currentRoom.mobs then
                mobsText = mobsText .. ", "
            end
        end
        love.graphics.print(mobsText, startX, startY + lineHeight * 7)
    else
        love.graphics.print("Mobs: Aucun", startX, startY + lineHeight * 7)
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

    for _, mob in ipairs(self.currentRoom.mobs) do
        mob:update(dt, {
            roomWidth  = self.roomWidth,
            roomHeight = self.roomHeight,
            scale      = _G.gameConfig.scaleX -- si besoin pour le draw
        })
    end
end



return GameState