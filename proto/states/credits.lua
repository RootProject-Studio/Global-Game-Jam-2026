-- states/credits.lua
-- État des crédits

local CreditsState = {}
local GameStateManager = require("gamestate")

function CreditsState:enter()
    self.scrollY = 600
    self.scrollSpeed = 30
    
    self.credits = {
        "",
        "",
        "THE BINDING OF ISAAC",
        "Clone",
        "",
        "",
        "Développement",
        "Votre Nom",
        "",
        "",
        "Inspiré par",
        "The Binding of Isaac",
        "par Edmund McMillen",
        "",
        "",
        "Moteur de jeu",
        "LÖVE2D",
        "",
        "",
        "Génération de labyrinthe",
        "Algorithme de génération procédurale",
        "inspiré de The Binding of Isaac",
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
    self.scrollY = self.scrollY - self.scrollSpeed * dt
    
    -- Recommencer si on a tout défilé
    if self.scrollY < -self.totalHeight then
        self.scrollY = 600
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
    love.graphics.printf("Appuyez sur Échap pour revenir au menu", 0, _G.gameConfig.windowHeight - 40 * scale, _G.gameConfig.windowWidth, "center")
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