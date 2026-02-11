local CreditsState = {}
local GameStateManager = require("gamestate")
local AudioManager = require("audio_manager")

function CreditsState:enter()
    -- Jouer la musique du menu seulement si elle ne joue pas déjà
    if not AudioManager:isMusicPlaying() then
        AudioManager:fadeInMusic("music/menu.ogg", 1.0, 0.5)
    end
    
    self.scrollY = 600
    self.scrollSpeed = 60
    self.scrollSpeedBase = self.scrollSpeed

    self.credits = {
        "",
        "",
        "LA VENGEANCE DE PEDRO",
        "",
        "",
        "Développement",
        "Gabin BOILLON",
        "Arthur COLLEU",
        "Thomas COUTANT",
        "Vital FOCHEUX",
        "Julien GAUTHIER",
        "Nicolas MENEGAUX",
        "",
        "",
        "Graphisme",
        "Milo GAUTHIER",
        "",
        "",
        "Musique",
        "Julien GAUTHIER",
        "",
        "",
        "Moteur de jeu",
        "LÖVE2D",
        "",
        "",
        "Merci d'avoir joué !",
        "",
        "",
        ""
    }
    self.totalHeight = #self.credits * 40
end

function CreditsState:update(dt)
    if love.keyboard.isDown("space") then
        self.scrollSpeed = self.scrollSpeedBase * 4
    else
        self.scrollSpeed = self.scrollSpeedBase
    end

    self.scrollY = self.scrollY - self.scrollSpeed * dt

    -- Revenir au menu si on a tout défilé
    if self.scrollY < -self.totalHeight then
        GameStateManager:setState("menu")
    end
end

function CreditsState:draw()
    love.graphics.clear(0.05, 0.05, 0.1)

    local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)

    -- Dessiner les crédits
    love.graphics.setColor(1, 1, 1)
    local y = self.scrollY
    local lineHeight = 40 * scale

    for i, line in ipairs(self.credits) do
        local alpha = 1

        -- Fade in/out en haut et en bas
        if y < 100 * scale then
            alpha = math.max(0, y / (100 * scale))
        elseif y > _G.gameConfig.windowHeight - 100 * scale then
            alpha = math.max(0, (_G.gameConfig.windowHeight - y) / (100 * scale))
        end
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.printf(line, 0, y, _G.gameConfig.windowWidth, "center")
        
        y = y + lineHeight
    end

    -- Instructions 
    love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
    love.graphics.printf("Appuyez sur Echap pour revenir au menu", 0, _G.gameConfig.windowHeight - 40 * scale, _G.gameConfig.windowWidth, "center")
end

function CreditsState:keypressed(key)
    if key == "escape" then
        GameStateManager:setState("menu")
    end
end

function CreditsState:exit()
end

-- Gestion du redimensionnement
function CreditsState:onResize()
    -- Pas d'ajustement spécifique nécessaire, juste redessiner
end

return CreditsState