-- states/options.lua
-- État des options

local OptionsState = {}
local GameStateManager = require("gamestate")

function OptionsState:enter()
    local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    
    self.baseButtons = {
        {
            text = "Retour au menu",
            baseX = 300,
            baseY = 200,
            baseWidth = 200,
            baseHeight = 60,
            action = function()
                GameStateManager:setState("menu")
            end
        }
    }
    
    self.hoveredButton = nil
    self:updateButtonPositions()
end

function OptionsState:updateButtonPositions()
    self.buttons = {}
    local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    
    -- Dimensions de base du conteneur des boutons
    local containerWidth = 200 * scale
    local containerHeight = 60 * scale
    
    -- Centrer le conteneur
    local containerX = (_G.gameConfig.windowWidth - containerWidth) / 2
    local containerY = (_G.gameConfig.windowHeight - containerHeight) / 2 + 50 * scale
    
    for i, baseButton in ipairs(self.baseButtons) do
        self.buttons[i] = {
            text = baseButton.text,
            x = containerX,
            y = containerY + (i - 1) * (baseButton.baseHeight * scale + 20 * scale),
            width = containerWidth,
            height = baseButton.baseHeight * scale,
            action = baseButton.action
        }
    end
end

function OptionsState:update(dt)
    local mx, my = love.mouse.getPosition()
    self.hoveredButton = nil
    
    for i, button in ipairs(self.buttons) do
        if mx >= button.x and mx <= button.x + button.width and
           my >= button.y and my <= button.y + button.height then
            self.hoveredButton = i
        end
    end
end

function OptionsState:draw()
    -- Fond
    love.graphics.clear(0.1, 0.1, 0.15)
    
    local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    
    -- Titre
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("OPTIONS", 0, 50 * scale, _G.gameConfig.windowWidth, "center")
    
    -- Boutons
    for i, button in ipairs(self.buttons) do
        if self.hoveredButton == i then
            love.graphics.setColor(0.8, 0.3, 0.3)
        else
            love.graphics.setColor(0.3, 0.3, 0.35)
        end
        
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 10, 10)
        
        -- Bordure
        love.graphics.setColor(0.6, 0.6, 0.65)
        love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 10, 10)
        
        -- Texte
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(button.text, button.x, button.y + 20 * scale, button.width, "center")
    end
end

function OptionsState:mousepressed(x, y, button)
    if button == 1 and self.hoveredButton then
        self.buttons[self.hoveredButton].action()
    end
end

function OptionsState:keypressed(key)
    if key == "escape" then
        GameStateManager:setState("menu")
    end
end

function OptionsState:exit()
end

-- Gestion du redimensionnement
function OptionsState:onResize()
    self:updateButtonPositions()
end

return OptionsState