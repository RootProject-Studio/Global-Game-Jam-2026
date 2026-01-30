-- states/menu.lua
-- État du menu principal

local MenuState = {}
local GameStateManager = require("gamestate")

function MenuState:enter()
    self.baseButtons = {
        {
            text = "Jouer",
            baseX = 300,
            baseY = 200,
            baseWidth = 200,
            baseHeight = 60,
            action = function()
                GameStateManager:setState("game")
            end
        },
        {
            text = "Options",
            baseX = 300,
            baseY = 280,
            baseWidth = 200,
            baseHeight = 60,
            action = function()
                GameStateManager:setState("options")
            end
        },
        {
            text = "Crédits",
            baseX = 300,
            baseY = 360,
            baseWidth = 200,
            baseHeight = 60,
            action = function()
                GameStateManager:setState("credits")
            end
        }
    }
    
    self.hoveredButton = nil
    self:updateButtonPositions()
end

function MenuState:updateButtonPositions()
    self.buttons = {}
    local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    
    -- Dimensions de base du conteneur des boutons
    local containerWidth = 200 * scale
    local containerHeight = 60 * scale * 3 + 30 * scale -- 3 boutons + espaces
    
    -- Centrer le conteneur
    local containerX = (_G.gameConfig.windowWidth - containerWidth) / 2
    local containerY = (_G.gameConfig.windowHeight - containerHeight) / 2 + 50 * scale -- Légèrement plus bas pour le titre
    
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

function MenuState:update(dt)
    local mx, my = love.mouse.getPosition()
    self.hoveredButton = nil
    
    for i, button in ipairs(self.buttons) do
        if mx >= button.x and mx <= button.x + button.width and
           my >= button.y and my <= button.y + button.height then
            self.hoveredButton = i
        end
    end
end

function MenuState:draw()
    -- Fond
    love.graphics.clear(0.1, 0.1, 0.15)
    
    local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    
    -- Titre
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("LA VENGEANCE DE PEDRO", 0, 80 * scale, _G.gameConfig.windowWidth, "center")
     
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

function MenuState:mousepressed(x, y, button)
    if button == 1 and self.hoveredButton then
        self.buttons[self.hoveredButton].action()
    end
end

function MenuState:keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end

function MenuState:exit()
end

-- Appeler cette fonction lors du redimensionnement
function MenuState:onResize()
    self:updateButtonPositions()
end

return MenuState