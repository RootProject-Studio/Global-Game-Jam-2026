-- states/game.lua
-- État du jeu principal

local GameState = {}
local GameStateManager = require("gamestate")
local DungeonGenerator = require("dungeon.generator")
local Pedro            = require("dungeon.mobs.player.pedro")
local Cyclope          = require("dungeon.masks.cyclope")
local Ffp2 = require("dungeon.masks.ffp2")
local Scream           = require("dungeon.masks.scream")
local AudioManager     = require("audio_manager")
local Anubis = require("dungeon.masks.anubis")
local Plague = require("dungeon.masks.plague_doctor")
local Paladin = require("dungeon.masks.paladin")
local Hydre = require("dungeon.masks.hydre")
local Magrit = require("dungeon.masks.magrit")
local Anonymous =require("dungeon.masks.anonymous")
local Luchador =require("dungeon.masks.luchador")
local Fire = require("dungeon.masks.fire")
local Medic =require("dungeon.masks.medic")
function GameState:enter()
    -- Jouer la musique du jeu avec transition fluide
    AudioManager:fadeInMusic("music/a_boss.ogg", 1.0, 0.5)

    -- Initialisation du joueur (une seule fois)
    self.player = Pedro:new()
    local cyclope = Cyclope:new()
    local ffp2 = Ffp2:new()
    local scream = Scream:new()
    local anubis = Anubis:new()
    local plague = Plague:new()
    local paladin = Paladin:new()
    local hydre = Hydre:new()
    local magrit = Magrit:new()
    local anonymous = Anonymous:new()
    local luchador = Luchador:new()
    local fire = Fire:new()
    local medic = Medic:new()
    self.player:equipMask(scream)

    self.items = {}

    -- Système de niveaux (persistant)
    self.currentLevel = 1
    self.defeatedBosses = {}
    
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
    
    -- Générer le premier donjon
    self:generateNewLevel()
    
    self:updateLayout()
end

function GameState:generateNewLevel()
    -- Générer un nouveau donjon (appelé à chaque niveau)
    if not DungeonGenerator then
        io.stderr:write("ERREUR: DungeonGenerator non trouvé!\n")
        self.currentRoom = nil
        self.dungeon = {}
        return
    end
    
    self.generator = DungeonGenerator:new()
    self.dungeon = self.generator:generate()
    self.generator:populateRooms(self.defeatedBosses)
    
    -- Trouver la salle de départ
    self.currentRoom = nil
    if self.dungeon then
        for _, room in ipairs(self.dungeon) do
            if room.type == DungeonGenerator.ROOM_TYPES.START then
                self.currentRoom = room
                break
            end
        end
    end
    
    if not self.currentRoom then
        io.stderr:write("ERREUR: Salle de départ non trouvée!\n")
    end
    
    -- Réinitialiser la position du joueur au centre de la salle de départ
    local scale = math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    local roomWidth = self.baseRoomWidth * scale
    local roomHeight = self.baseRoomHeight * scale
    local roomX = (_G.gameConfig.windowWidth - roomWidth) / 2
    local roomY = (_G.gameConfig.windowHeight - roomHeight) / 2
    
    self.player.x = roomX + roomWidth / 2
    self.player.y = roomY + roomHeight / 2
    
    -- Nettoyer les projectiles
    self.player.projectiles = {}
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
    if not self.currentRoom then return end

    if self.player
        and self.player.maskManager
        and self.player.maskManager.open then
            return
    end


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
    

    local roomCleared = true
    if self.currentRoom.mobs and #self.currentRoom.mobs > 0 then
        roomCleared = false
    end

    -- Vérifier si le boss est vaincu et créer la porte de niveau
    if self.currentRoom.type == DungeonGenerator.ROOM_TYPES.BOSS then
        -- Activer la porte de niveau si le boss est vaincu
        if roomCleared and not self.currentRoom.levelDoorActive then
            self.currentRoom.levelDoorActive = true
            
            -- Sauvegarder le boss vaincu
            if self.currentRoom.bossType then
                local alreadySaved = false
                for _, defeatedBoss in ipairs(self.defeatedBosses) do
                    if defeatedBoss == self.currentRoom.bossType then
                        alreadySaved = true
                        break
                    end
                end
                if not alreadySaved then
                    table.insert(self.defeatedBosses, self.currentRoom.bossType)
                end
            end
        end
        
        -- Vérifier collision avec la porte de niveau
        if self.currentRoom.levelDoorActive then
            local doorX = self.roomX + self.roomWidth / 2
            local doorY = self.roomY + self.roomHeight - 40
            local doorWidth = 80
            local doorHeight = 40
            
            if playerX > doorX - doorWidth/2 and playerX < doorX + doorWidth/2 and
               playerY > doorY and playerY < doorY + doorHeight then
                -- Passer au niveau suivant
                self.currentLevel = self.currentLevel + 1
                self:generateNewLevel()
                return
            end
        end
    end


    -- Vérifier si la salle contient un trader
    local hasTrader = false
    if self.currentRoom.mobs then
        for _, mob in ipairs(self.currentRoom.mobs) do
            if mob.subtype == "traider" then
                hasTrader = true
                break
            end
        end
    end
    
    -- Vérifier si la salle est dégagée de tous les ennemis (pour les portes normales)
    -- Les salles avec trader restent toujours ouvertes
    local canExit = roomCleared or hasTrader or (self.currentRoom.type == DungeonGenerator.ROOM_TYPES.BOSS and self.currentRoom.levelDoorActive)
    
    -- Porte du haut
    if canExit and self.currentRoom.doors.top and playerY < self.roomY + doorThreshold then
        local centerX = self.roomX + self.roomWidth / 2
        if playerX > centerX - doorWidth/2 and playerX < centerX + doorWidth/2 then
            self:changeRoom(0, -1)
            self.player.y = self.roomY + self.roomHeight * 0.85
            return
        end
    end
    
    -- Porte du bas
    if canExit and self.currentRoom.doors.bottom and playerY > self.roomY + self.roomHeight - doorThreshold then
        local centerX = self.roomX + self.roomWidth / 2
        if playerX > centerX - doorWidth/2 and playerX < centerX + doorWidth/2 then
            self:changeRoom(0, 1)
            self.player.y = self.roomY + self.roomHeight * 0.15
            return
        end
    end
    
    -- Porte de gauche
    if canExit and self.currentRoom.doors.left and playerX < self.roomX + doorThreshold then
        local centerY = self.roomY + self.roomHeight / 2
        if playerY > centerY - doorWidth/2 and playerY < centerY + doorWidth/2 then
            self:changeRoom(-1, 0)
            self.player.x = self.roomX + self.roomWidth * 0.85
            return
        end
    end
    
    -- Porte de droite
    if canExit and self.currentRoom.doors.right and playerX > self.roomX + self.roomWidth - doorThreshold then
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

    -- Initialiser les items de la salle s'ils n'existent pas
    if not self.currentRoom.items then
        self.currentRoom.items = {}
    end

    -- Update items
    for _, item in ipairs(self.currentRoom.items) do
        item:update(dt)
    end

    -- Collision item<->player
    self:checkItemCollisions()

    -- Remove collected items
    local i = #self.currentRoom.items
    while i >= 1 do
        if self.currentRoom.items[i]:isDead() then
            table.remove(self.currentRoom.items, i)
        end
        i = i - 1
    end
end

function GameState:draw()
    love.graphics.clear(0.15, 0.1, 0.1)
    
    -- Vérifier que la salle existe
    if not self.currentRoom then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Erreur: Salle non chargée!", 0, _G.gameConfig.windowHeight / 2 - 50, _G.gameConfig.windowWidth, "center")
        return
    end
    
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
                roomHeight = self.roomHeight,
                playerX = self.player.x,
                playerY = self.player.y,
                player = self.player,
                scale = _G.gameConfig.scaleX or 1,
                debugMode = self.debugMode
            })
        end
    end

    if self.currentRoom and self.currentRoom.items then
        for _, item in ipairs(self.currentRoom.items) do
            item:draw({
                roomX = self.roomX,
                roomY = self.roomY,
                roomWidth = self.roomWidth,
                roomHeight = self.roomHeight,
                scale = _G.gameConfig.scaleX or 1
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

    if self.player.maskManager.open then
        self:drawMaskInventory()
    end



    -- Instructions en bas
    love.graphics.setColor(1, 1, 1)
    local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    local fontSize = math.max(12, 12 * scale)
    love.graphics.setNewFont(fontSize)
    local padding = 20 * scale
    love.graphics.print("P: debug | M: carte | F5 : Régénerer | Echap: menu", padding, _G.gameConfig.windowHeight - padding - 10)
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

    -- Cooldown d'invincibilité
    local hitCD = self.player.hitCooldown or 0
    love.graphics.print(
        string.format("Invincibilité: %.2fs", hitCD),
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

      -- Porte de niveau (après boss)
    if self.currentRoom.type == DungeonGenerator.ROOM_TYPES.BOSS and self.currentRoom.levelDoorActive then
        local doorX = self.roomX + self.roomWidth / 2
        local doorY = self.roomY + self.roomHeight - 40
        local doorWidth = 80
        local doorHeight = 40
        
        -- Porte dorée qui pulse
        local pulse = 0.7 + 0.3 * math.sin(love.timer.getTime() * 3)
        
        -- Fond doré
        love.graphics.setColor(1, 0.8, 0, 0.8 * pulse)
        love.graphics.rectangle("fill", doorX - doorWidth/2, doorY, doorWidth, doorHeight, 5, 5)
        
        -- Contour brillant
        love.graphics.setColor(1, 1, 0.5, pulse)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", doorX - doorWidth/2, doorY, doorWidth, doorHeight, 5, 5)
        
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
    local mm = self.player.maskManager

    if mm then
        if mm.pickupMode then
            if key == "left" then
                mm:moveSelection("left")
            elseif key == "right" then
                mm:moveSelection("right")
            elseif key == "return" then
                mm:confirmPickup(self.player)
            elseif key == "backspace" then
                mm:cancelPickup()
            elseif key == "up" or key == "down" then
                self:updateMaskScroll(key)
            end
            return
        end

        if key == "r" then
            mm:toggle()
            return
        end

        if mm.open then
            if key == "left" then mm:selectPrev()
            elseif key == "right" then mm:selectNext()
            elseif key == "backspace" then
                mm:unequip(mm.selectedSlot)
            elseif key == "up" or key == "down" then
                self:updateMaskScroll(key)
            end
            return
        end
    end

    -- Inputs normaux du jeu
    -- Vérifier si un shop est ouvert
    for _, mob in ipairs(self.currentRoom.mobs) do
        if mob.subtype == "traider" and mob.shopOpen then
            mob:shopKeypressed(key, self.player)
            return -- stop, le joueur ne bouge pas
        end
    end

    -- Pas de shop ouvert : gestion normale
    if key == "escape" then
        GameStateManager:setState("menu")
    elseif key == "m" then
        self.showMap = not self.showMap
    elseif key == "p" then
        self.debugMode = not self.debugMode
    elseif key == "f5" then
        self:enter()
    end
end



function GameState:exit()
    -- Revenir à la musique du menu avec transition fluide
    AudioManager:fadeInMusic("music/menu.ogg", 0.5, 0.5)
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
        doors = self.currentRoom.doors,
        player = self.player,   -- ✅ ici on passe le joueur
        debugMode = self.debugMode
    })
end


    -- 2) Remove dead mobs from the room
    local i = #self.currentRoom.mobs
    while i >= 1 do
        if self.currentRoom.mobs[i]:isDead() then
            -- Récupérer l'item droppé avant de supprimer le mob
            local droppedItem = self.currentRoom.mobs[i]:onDeath()
            if droppedItem then
                -- Ajouter l'item à la salle actuelle au lieu de self.items
                if not self.currentRoom.items then
                    self.currentRoom.items = {}
                end
                table.insert(self.currentRoom.items, droppedItem)
            end
            table.remove(self.currentRoom.mobs, i)
        end
        i = i - 1
    end

   -- 2) Build absolute positions and radii
    local mobCount = #self.currentRoom.mobs
    local abs = {}
    for i, mob in ipairs(self.currentRoom.mobs) do
        local mx = roomX + mob.relX * roomW
        local my = roomY + mob.relY * roomH
        local mr = (mob.size or 10) * scale
        abs[i] = {mob = mob, x = mx, y = my, r = mr, underground = (mob.state == "underground")}
    end

    -- 3) Resolve mob↔mob collisions (simple push-apart)
    for i = 1, mobCount do
        for j = i+1, mobCount do
            local a = abs[i]
            local b = abs[j]
            -- Skip si l'un des deux est sous terre
            if a.underground or b.underground then goto continue_mob end
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
                local nx = dx / dist
                local ny = dy / dist
                local pushAX = nx * (overlap * 0.5)
                local pushAY = ny * (overlap * 0.5)
                local pushBX = -nx * (overlap * 0.5)
                local pushBY = -ny * (overlap * 0.5)

                a.x = a.x + pushAX
                a.y = a.y + pushAY
                b.x = b.x + pushBX
                b.y = b.y + pushBY
            end
            ::continue_mob::
        end
    end
    -- 4) Write back adjusted mob rel positions and clamp to room
    for i, info in ipairs(abs) do
        local m = info.mob
        m.relX = math.max(0, math.min(1, (info.x - roomX) / roomW))
        m.relY = math.max(0, math.min(1, (info.y - roomY) / roomH))
    end

    -- 5) Resolve mob<->player collisions (push player away and keep player inside room)
    for _, info in ipairs(abs) do
        
        if info.underground then goto continue_player end
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
        ::continue_player::
    end
end

function GameState:checkItemCollisions()
    if not self.player or not self.currentRoom.items or #self.currentRoom.items == 0 then return end
        
    local scale = _G.gameConfig.scaleX or 1
    local playerRadius = self.player.size or 8
    
    for _, item in ipairs(self.currentRoom.items) do
        local itemPos = item:getAbsolutePos({
            roomX = self.roomX,
            roomY = self.roomY,
            roomWidth = self.roomWidth,
            roomHeight = self.roomHeight,
            scale = scale
        })
        
        local dx = self.player.x - itemPos.x
        local dy = self.player.y - itemPos.y
        local dist = math.sqrt(dx*dx + dy*dy)
        local minDist = playerRadius + itemPos.r
        
        if dist < minDist then
            
            local maskClass = {
                cyclope = Cyclope,
                ffp2 = Ffp2,
                scream = Scream,
                anubis = Anubis,
                plague = Plague,
                paladin = Paladin,
                hydre = Hydre,
                magrit = Magrit,
                anonymous = Anonymous,
                luchador = Luchador,
                medic = Medic
            }
            
            if maskClass[item.maskType] then
                local newMask = maskClass[item.maskType]:new()
                self.player.maskManager:startPickup(newMask)
            end

            item:collect()  -- retirer l'item du sol
        end
    end
end



function GameState:drawMaskInventory()
    local mm = self.player.maskManager
    if not mm or not mm.open then return end

    if mm.pickupMode then
        self:drawMaskPickup()
    else
        self:drawMaskInventoryNormal()
    end
end

function GameState:drawMaskPickup()
    local mm = self.player.maskManager
    local scale = _G.gameConfig.scale or 1
    local screenW = _G.gameConfig.windowWidth
    local screenH = _G.gameConfig.windowHeight

    local slotW, slotH = 220 * scale, 300 * scale
    local centerW, centerH = 260 * scale, 360 * scale
    local spacing = 40 * scale
    local y = screenH/2 - slotH/2

    local centerX = screenW/2 - centerW/2
    local leftX   = centerX - spacing - slotW
    local rightX  = centerX + centerW + spacing

    -- Fond global
    love.graphics.setColor(0,0,0,0.85)
    love.graphics.rectangle("fill", 0, 0, screenW, screenH)

    -- ===== SLOT GAUCHE (DÉTAILLÉ) =====
    love.graphics.setColor(0.1,0.1,0.1,0.9)
    love.graphics.rectangle("fill", leftX, y, slotW, slotH)

    if mm.slots[1] then
        self:drawMaskDetails(
            mm.slots[1],
            leftX,
            y,
            slotW,
            slotH,
            mm.scrollOffset
        )
    else
        love.graphics.setColor(0.6,0.6,0.6)
        love.graphics.printf("Vide", leftX, y + slotH/2 - 10, slotW, "center")
    end

    if mm.selectedSlot == 1 then
        love.graphics.setColor(1,1,0)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", leftX, y, slotW, slotH)
    end

    -- ===== SLOT DROIT (DÉTAILLÉ) =====
    love.graphics.setColor(0.1,0.1,0.1,0.9)
    love.graphics.rectangle("fill", rightX, y, slotW, slotH)

    if mm.slots[2] then
        self:drawMaskDetails(
            mm.slots[2],
            rightX,
            y,
            slotW,
            slotH,
            mm.scrollOffset
        )
    else
        love.graphics.setColor(0.6,0.6,0.6)
        love.graphics.printf("Vide", rightX, y + slotH/2 - 10, slotW, "center")
    end

    if mm.selectedSlot == 2 then
        love.graphics.setColor(1,1,0)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", rightX, y, slotW, slotH)
    end

    -- ===== MASQUE RAMASSÉ (CENTRE, DÉTAILLÉ) =====
    local mask = mm.pickingUpMask
    if mask then
        love.graphics.setColor(0.1,0.1,0.1,0.95)
        love.graphics.rectangle("fill", centerX, y - 20*scale, centerW, centerH)

        self:drawMaskDetails(
            mask,
            centerX,
            y - 20*scale,
            centerW,
            centerH,
            mm.pickupScroll
        )
    end

    -- Aide contrôles
    love.graphics.setColor(1,1,1)
    love.graphics.printf(
        "<- | -> Choisir slot   |   Entrée : équiper   |   Backspace ou Sup : drop",
        0,
        screenH - 40*scale,
        screenW,
        "center"
    )
end

function GameState:drawMaskSlot(mask, x, y, w, h, selected)
    local scale = _G.gameConfig.scale or 1

    love.graphics.setColor(0.1,0.1,0.1,0.9)
    love.graphics.rectangle("fill", x, y, w, h)

    if selected then
        love.graphics.setColor(1,1,0)
        love.graphics.setLineWidth(3)
        love.graphics.rectangle("line", x, y, w, h)
    end

    if not mask or not mask.getInfo then
        love.graphics.setColor(0.6,0.6,0.6)
        love.graphics.printf("Vide", x, y + h/2 - 10, w, "center")
        return
    end

    local info = mask:getInfo()

    if info.imagePath then
        local img = love.graphics.newImage(info.imagePath)
        local imgScale = math.min(w*0.6 / img:getWidth(), h*0.4 / img:getHeight())
        love.graphics.setColor(1,1,1)
        love.graphics.draw(
            img,
            x + w/2,
            y + h*0.3,
            0,
            imgScale,
            imgScale,
            img:getWidth()/2,
            img:getHeight()/2
        )
    end

    if info.name then
        love.graphics.setColor(1,1,1)
        love.graphics.printf(info.name, x, y + h*0.65, w, "center")
    end
end

function GameState:drawMaskDetails(mask, x, y, w, h, scrollOffset)
    if not mask or not mask.getInfo then return end
    local info = mask:getInfo()
    local scale = _G.gameConfig.scale or 1

    -- Image
    if info.imagePath then
        local img = love.graphics.newImage(info.imagePath)
        local imgScale = math.min(w / 2 / img:getWidth(), (h/3) / img:getHeight())
        love.graphics.setColor(1,1,1)
        love.graphics.draw(
            img,
            x + w/2,
            y + h/6,
            0,
            imgScale,
            imgScale,
            img:getWidth()/2,
            img:getHeight()/2
        )
    end

    -- Description
    if info.description then
        love.graphics.setColor(1,1,1)
        love.graphics.printf(info.description, x + 10, y + h/3, w - 20, "center")
    end

    -- Paramètres
    local paramsY = y + h/2
    local spacing = 20 * scale
    local textHeight = h - (paramsY - y) - 10

    love.graphics.setScissor(x, paramsY, w, textHeight)

    local lineY = paramsY - (scrollOffset or 0)
    for k,v in pairs(info) do
        if k ~= "imagePath" and k ~= "description" then
            love.graphics.print(k .. ": " .. tostring(v), x + 10, lineY)
            lineY = lineY + spacing
        end
    end

    love.graphics.setScissor()
end


function GameState:drawMaskInventoryNormal()
    local mm = self.player.maskManager
    if not mm or not mm.open then return end
    local screenW = _G.gameConfig.windowWidth
    local screenH = _G.gameConfig.windowHeight
    local scale = _G.gameConfig.scale or 1
    local width, height = 250 * scale, 350 * scale -- un peu plus petit
    local slotSpacing = 50 * scale
    local totalWidth = width * 2 + slotSpacing
    local startX = (_G.gameConfig.windowWidth - totalWidth) / 2
    local y = 100 * scale

    love.graphics.setColor(0, 0, 0, 0.8)
    -- Fond du slot gauche
    love.graphics.rectangle("fill", startX, y, width, height)
    -- Fond du slot droit
    love.graphics.rectangle("fill", startX + width + slotSpacing, y, width, height)

    for i, slotX in ipairs({startX, startX + width + slotSpacing}) do
        local mask = mm.slots[i]

        -- Cadre de sélection
        if mm.selectedSlot == i then
            love.graphics.setColor(1, 1, 0)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", slotX, y, width, height)
        end

        if mask then
            self:drawMaskDetails(mask, slotX, y, width, height, mm.scrollOffset)
        else
            love.graphics.setColor(0.5,0.5,0.5)
            love.graphics.print("Vide", slotX + width/2 - 20, y + height/2)
        end

    end

    if mm.pickingUpMask then
        local pickX = screenW/2
        local pickY = y - 100*scale
        local info = mm.pickingUpMask:getInfo()

        -- Image au centre
        if info.imagePath then
            local img = love.graphics.newImage(info.imagePath)
            love.graphics.setColor(1,1,1)
            local imgScale = 0.5*scale
            love.graphics.draw(img, pickX, pickY, 0, imgScale, imgScale, img:getWidth()/2, img:getHeight()/2)
        end

        -- Description
        if info.description then
            love.graphics.setColor(1,1,1)
            love.graphics.printf(info.description, pickX - width/2, pickY + 50, width, "center")
        end

        -- Paramètres
        local lineY = pickY + 80 + mm.pickupScroll
        for k,v in pairs(info) do
            if k ~= "imagePath" and k ~= "description" then
                love.graphics.setColor(1,1,1)
                love.graphics.print(k..": "..tostring(v), pickX - width/2 + 10, lineY)
                lineY = lineY + 22*scale
            end
        end
    end
    -- Aide contrôles
    love.graphics.setColor(1,1,1)
    love.graphics.printf(
        "<- | -> Choisir slot   | Backspace ou Sup : drop",
        0,
        screenH - 40*scale,
        screenW,
        "center"
    )

end

function GameState:updateMaskScroll(key)
    local mm = self.player.maskManager
    if not mm or not mm.open then return end

    local scrollStep = 20 * (_G.gameConfig.scale or 1)  -- décalage par flèche

    -- Récupérer le slot sélectionné
    local mask = mm.slots[mm.selectedSlot]
    if not mask or not mask.getInfo then return end
    local info = mask:getInfo()

    -- Calculer la hauteur totale des paramètres à afficher
    local spacing = 20 * (_G.gameConfig.scale or 1)
    local totalLines = 0
    for k,v in pairs(info) do
        if k ~= "imagePath" and k ~= "description" then
            totalLines = totalLines + 1
        end
    end
    local totalHeight = totalLines * spacing

    local height = 350 * (_G.gameConfig.scale or 1)
    local paramsY = height/2  -- même calcul que dans drawMaskInventory
    local visibleHeight = height - (paramsY) - 10  -- espace disponible pour le texte

    mm.scrollOffset = mm.scrollOffset or 0

    -- Gestion scroll
    if key == "down" then
        mm.scrollOffset = math.min(mm.scrollOffset + scrollStep, math.max(0, totalHeight - visibleHeight))
    elseif key == "up" then
        mm.scrollOffset = math.max(mm.scrollOffset - scrollStep, 0)
    end

    
end

return GameState