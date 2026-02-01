-- audio_manager.lua
-- Gestionnaire de musique et sons du jeu

local AudioManager = {
    currentMusic = nil,
    musicVolume = 0.5,
    soundVolume = 0.7,
    musicFading = false,
    fadeDuration = 0,
    fadeProgress = 0,
    fadeTarget = 0
}

-- Lire une musique (en boucle)
function AudioManager:playMusic(musicPath, volume)
    volume = volume or self.musicVolume
    
    if not love.filesystem.getInfo(musicPath) then
        io.stderr:write("Musique non trouvée: " .. musicPath .. "\n")
        return false
    end
    
    -- Arrêter la musique actuelle
    if self.currentMusic then
        self.currentMusic:stop()
    end
    
    -- Charger et jouer la nouvelle musique
    self.currentMusic = love.audio.newSource(musicPath, "stream")
    self.currentMusic:setVolume(volume)
    self.currentMusic:setLooping(true)
    self.currentMusic:play()
    
    self.musicVolume = volume
    self.musicFading = false
    
    io.stderr:write("Musique jouée: " .. musicPath .. "\n")
    return true
end

-- Arrêter la musique
function AudioManager:stopMusic()
    if self.currentMusic then
        self.currentMusic:stop()
        self.currentMusic = nil
    end
    self.musicFading = false
end

-- Faire un fondu de la musique (transition en douceur)
function AudioManager:fadeOutMusic(duration)
    if not self.currentMusic then return end
    
    self.musicFading = true
    self.fadeDuration = duration
    self.fadeProgress = 0
    self.fadeTarget = 0 -- Cible: volume 0
end

-- Faire un fondu d'entrée de la musique
function AudioManager:fadeInMusic(musicPath, duration, targetVolume)
    duration = duration or 1.0
    targetVolume = targetVolume or self.musicVolume
    
    if not love.filesystem.getInfo(musicPath) then
        io.stderr:write("Musique non trouvée: " .. musicPath .. "\n")
        return false
    end
    
    -- Arrêter la musique actuelle
    if self.currentMusic then
        self.currentMusic:stop()
    end
    
    -- Charger la nouvelle musique avec volume 0
    self.currentMusic = love.audio.newSource(musicPath, "stream")
    self.currentMusic:setVolume(0)
    self.currentMusic:setLooping(true)
    self.currentMusic:play()
    
    -- Configurer le fade in
    self.musicFading = true
    self.fadeDuration = duration
    self.fadeProgress = 0
    self.fadeTarget = targetVolume
    
    io.stderr:write("Fondu d'entrée: " .. musicPath .. "\n")
    return true
end

-- Mettre à jour le fade de la musique
function AudioManager:update(dt)
    if self.musicFading and self.currentMusic then
        self.fadeProgress = self.fadeProgress + dt
        
        if self.fadeProgress >= self.fadeDuration then
            self.fadeProgress = self.fadeDuration
            self.musicFading = false
            
            if self.fadeTarget == 0 then
                self.currentMusic:stop()
                self.currentMusic = nil
                return  -- Sortir immédiatement après arrêt
            end
        end
        
        -- Vérifier que currentMusic existe toujours avant d'y accéder
        if not self.currentMusic then return end
        
        -- Calculer le volume intermédiaire
        local progress = self.fadeProgress / self.fadeDuration
        local currentVolume = self.currentMusic:getVolume()
        local newVolume = currentVolume + (self.fadeTarget - currentVolume) * progress
        self.currentMusic:setVolume(math.max(0, newVolume))
    end
end

-- Jouer un son (une seule fois)
function AudioManager:playSound(soundPath, volume)
    volume = volume or self.soundVolume
    
    if not love.filesystem.getInfo(soundPath) then
        io.stderr:write("Son non trouvé: " .. soundPath .. "\n")
        return false
    end
    
    local sound = love.audio.newSource(soundPath, "static")
    sound:setVolume(volume)
    sound:play()
    
    return true
end

-- Régler le volume de la musique
function AudioManager:setMusicVolume(volume)
    self.musicVolume = math.max(0, math.min(1, volume))
    if self.currentMusic and not self.musicFading then
        self.currentMusic:setVolume(self.musicVolume)
    end
end

-- Régler le volume des sons
function AudioManager:setSoundVolume(volume)
    self.soundVolume = math.max(0, math.min(1, volume))
end

-- Vérifier si une musique est en cours
function AudioManager:isMusicPlaying()
    return self.currentMusic ~= nil and self.currentMusic:isPlaying()
end

return AudioManager
