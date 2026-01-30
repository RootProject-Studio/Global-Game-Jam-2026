-- dungeon/generator.lua
-- Générateur de labyrinthe style The Binding of Isaac

local DungeonGenerator = {}

-- Types de salles
DungeonGenerator.ROOM_TYPES = {
    NORMAL = "normal",
    START = "start",
    BOSS = "boss",
    SHOP = "shop"
}

-- Configuration par défaut
DungeonGenerator.config = {
    minRooms = 10,
    maxRooms = 18,
    gridSize = 13, -- Grille 13x13 comme dans TBOI
    -- Boss et Shop sont toujours présents et dans des impasses
}

function DungeonGenerator:new()
    local generator = {}
    setmetatable(generator, {__index = self})
    return generator
end

function DungeonGenerator:generate()
    self.grid = {}
    self.rooms = {}
    self.roomCount = 0

    math.randomseed(os.time())
    
    -- Initialiser la grille
    local size = self.config.gridSize
    for x = 1, size do
        self.grid[x] = {}
        for y = 1, size do
            self.grid[x][y] = nil
        end
    end
    
    -- Position de départ (centre de la grille)
    local startX = math.floor(size / 2) + 1
    local startY = math.floor(size / 2) + 1
    
    -- Créer la salle de départ
    self:createRoom(startX, startY, self.ROOM_TYPES.START)
    
    -- Générer le nombre cible de salles
    local targetRooms = math.random(self.config.minRooms, self.config.maxRooms)
    
    -- Liste des salles disponibles pour expansion
    local availableRooms = {{x = startX, y = startY}}
    
    -- Générer les salles
    while self.roomCount < targetRooms and #availableRooms > 0 do
        -- Choisir une salle aléatoire à partir de laquelle étendre
        local index = math.random(1, #availableRooms)
        local currentRoom = availableRooms[index]
        
        -- Essayer de créer une nouvelle salle adjacente
        local directions = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}} -- Haut, Droite, Bas, Gauche
        self:shuffleTable(directions)
        
        local expanded = false
        for _, dir in ipairs(directions) do
            local newX = currentRoom.x + dir[1]
            local newY = currentRoom.y + dir[2]
            
            if self:canPlaceRoom(newX, newY) then
                self:createRoom(newX, newY, self.ROOM_TYPES.NORMAL)
                table.insert(availableRooms, {x = newX, y = newY})
                expanded = true
                break
            end
        end
        
        -- Si aucune direction n'est disponible, retirer cette salle de la liste
        if not expanded then
            table.remove(availableRooms, index)
        end
    end
    
    -- Placer les salles spéciales
    self:placeSpecialRooms()
    
    -- Calculer les connexions entre les salles
    self:calculateConnections()
    
    return self.rooms
end

function DungeonGenerator:canPlaceRoom(x, y)
    local size = self.config.gridSize
    
    -- Vérifier les limites de la grille
    if x < 1 or x > size or y < 1 or y > size then
        return false
    end
    
    -- Vérifier si la case est déjà occupée
    if self.grid[x][y] then
        return false
    end
    
    -- Compter les salles adjacentes (orthogonales)
    local adjacentCount = 0
    local directions = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}}
    
    for _, dir in ipairs(directions) do
        local checkX = x + dir[1]
        local checkY = y + dir[2]
        
        if checkX >= 1 and checkX <= size and checkY >= 1 and checkY <= size then
            if self.grid[checkX][checkY] then
                adjacentCount = adjacentCount + 1
            end
        end
    end
    
    -- Vérifier les salles en diagonale pour éviter les clusters
    local diagonalCount = 0
    local diagonals = {{-1, -1}, {1, -1}, {1, 1}, {-1, 1}}
    
    for _, diag in ipairs(diagonals) do
        local checkX = x + diag[1]
        local checkY = y + diag[2]
        
        if checkX >= 1 and checkX <= size and checkY >= 1 and checkY <= size then
            if self.grid[checkX][checkY] then
                diagonalCount = diagonalCount + 1
            end
        end
    end
    
    -- Pour un donjon labyrinthique :
    -- - Une salle doit avoir exactement 1 salle adjacente (crée des corridors)
    -- - Éviter d'avoir plus de 1 salle en diagonale (évite les gros blocs)
    -- Plus tard dans la génération (> 60% des salles), on permet 2 adjacentes
    local roomRatio = self.roomCount / self.config.maxRooms
    local maxAdjacent = roomRatio > 0.6 and 2 or 1
    
    return adjacentCount >= 1 and adjacentCount <= maxAdjacent and diagonalCount <= 1
end

function DungeonGenerator:createRoom(x, y, roomType)
    local room = {
        x = x,
        y = y,
        type = roomType,
        gridX = x,
        gridY = y,
        doors = {
            top = false,
            right = false,
            bottom = false,
            left = false
        },
        cleared = roomType == self.ROOM_TYPES.START -- La salle de départ est déjà nettoyée
    }
    
    self.grid[x][y] = room
    table.insert(self.rooms, room)
    self.roomCount = self.roomCount + 1
    
    return room
end

function DungeonGenerator:calculateConnections()
    local directions = {
        {dx = 0, dy = -1, door = "top", opposite = "bottom"},
        {dx = 1, dy = 0, door = "right", opposite = "left"},
        {dx = 0, dy = 1, door = "bottom", opposite = "top"},
        {dx = -1, dy = 0, door = "left", opposite = "right"}
    }
    
    for _, room in ipairs(self.rooms) do
        for _, dir in ipairs(directions) do
            local neighborX = room.gridX + dir.dx
            local neighborY = room.gridY + dir.dy
            
            if self.grid[neighborX] and self.grid[neighborX][neighborY] then
                room.doors[dir.door] = true
                self.grid[neighborX][neighborY].doors[dir.opposite] = true
            end
        end
    end
end

function DungeonGenerator:placeSpecialRooms()
    -- Trouver les salles candidates (salles normales avec une seule porte = dead ends)
    local deadEnds = {}
    
    for _, room in ipairs(self.rooms) do
        if room.type == self.ROOM_TYPES.NORMAL then
            local doorCount = 0
            for _, hasDoor in pairs(room.doors) do
                if hasDoor then doorCount = doorCount + 1 end
            end
            
            if doorCount == 1 then
                table.insert(deadEnds, room)
            end
        end
    end
    
    -- S'assurer qu'il y a au moins 2 impasses pour le boss et le shop
    while #deadEnds < 2 do
        if not self:createDeadEnd() then
            -- Si on ne peut pas créer d'impasse, arrêter
            break
        end
        
        -- Recalculer les impasses
        deadEnds = {}
        for _, room in ipairs(self.rooms) do
            if room.type == self.ROOM_TYPES.NORMAL then
                local doorCount = 0
                for _, hasDoor in pairs(room.doors) do
                    if hasDoor then doorCount = doorCount + 1 end
                end
                
                if doorCount == 1 then
                    table.insert(deadEnds, room)
                end
            end
        end
    end
    
    -- Placer la salle du boss (OBLIGATOIRE - la plus éloignée du départ)
    if #deadEnds > 0 then
        local bossRoom = self:getFarthestRoom(deadEnds)
        bossRoom.type = self.ROOM_TYPES.BOSS
    end
    
    -- Placer la boutique (OBLIGATOIRE - dans une impasse différente)
    if #deadEnds > 1 then
        local shopRoom = self:getRandomRoom(deadEnds, self.ROOM_TYPES.BOSS)
        if shopRoom then
            shopRoom.type = self.ROOM_TYPES.SHOP
        end
    end
end

function DungeonGenerator:getFarthestRoom(rooms)
    local startRoom = self:getStartRoom()
    local farthest = rooms[1]
    local maxDistance = 0
    
    for _, room in ipairs(rooms) do
        if room.type == self.ROOM_TYPES.NORMAL then
            local distance = math.abs(room.gridX - startRoom.gridX) + math.abs(room.gridY - startRoom.gridY)
            if distance > maxDistance then
                maxDistance = distance
                farthest = room
            end
        end
    end
    
    return farthest
end

function DungeonGenerator:getRandomRoom(rooms, ...)
    local excludeTypes = {...}
    local validRooms = {}
    
    for _, room in ipairs(rooms) do
        local valid = true
        for _, excludeType in ipairs(excludeTypes) do
            if room.type == excludeType then
                valid = false
                break
            end
        end
        if valid then
            table.insert(validRooms, room)
        end
    end
    
    if #validRooms > 0 then
        return validRooms[math.random(1, #validRooms)]
    end
    
    return nil
end

function DungeonGenerator:getStartRoom()
    for _, room in ipairs(self.rooms) do
        if room.type == self.ROOM_TYPES.START then
            return room
        end
    end
end

function DungeonGenerator:shuffleTable(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function DungeonGenerator:createDeadEnd()
    -- Trouver une salle normale qui peut avoir une extension
    local candidateRooms = {}
    
    for _, room in ipairs(self.rooms) do
        if room.type == self.ROOM_TYPES.NORMAL then
            -- Vérifier s'il y a de l'espace pour ajouter une salle adjacente
            local directions = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}}
            
            for _, dir in ipairs(directions) do
                local newX = room.gridX + dir[1]
                local newY = room.gridY + dir[2]
                
                if self:canPlaceRoomForced(newX, newY) then
                    table.insert(candidateRooms, {room = room, x = newX, y = newY})
                end
            end
        end
    end
    
    -- Si on a des candidats, créer une impasse
    if #candidateRooms > 0 then
        local candidate = candidateRooms[math.random(1, #candidateRooms)]
        self:createRoom(candidate.x, candidate.y, self.ROOM_TYPES.NORMAL)
        self:calculateConnections()
        return true
    end
    
    return false
end

function DungeonGenerator:canPlaceRoomForced(x, y)
    local size = self.config.gridSize
    
    -- Vérifier les limites de la grille
    if x < 1 or x > size or y < 1 or y > size then
        return false
    end
    
    -- Vérifier si la case est déjà occupée
    if self.grid[x][y] then
        return false
    end
    
    -- Compter les salles adjacentes
    local adjacentCount = 0
    local directions = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}}
    
    for _, dir in ipairs(directions) do
        local checkX = x + dir[1]
        local checkY = y + dir[2]
        
        if checkX >= 1 and checkX <= size and checkY >= 1 and checkY <= size then
            if self.grid[checkX][checkY] then
                adjacentCount = adjacentCount + 1
            end
        end
    end
    
    -- Pour créer une impasse forcée, on accepte une seule connexion
    return adjacentCount == 1
end

return DungeonGenerator