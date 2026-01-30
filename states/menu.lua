local Transitions = require("transitions")
local GameStateManager = require("gamestate")

local MenuState = {
    buttons = {},
    selectedButton = 1
}

function MenuState:enter()
    self.buttons = {
        {x = 0, y = 0, width = 200, height = 50, label = "Jouer", action = function() 
            Transitions:start("fade", 0.5)
            -- Vous pouvez changer d'état après
        end},
        {x = 0, y = 0, width = 200, height = 50, label = "Options", action = function() 
            Transitions:start("slideLeft", 0.3)
            GameStateManager:setState("options")
        end},
        {x = 0, y = 0, width = 200, height = 50, label = "Crédits", action = function() 
            Transitions:start("slideLeft", 0.3)
            GameStateManager:setState("credits")
        end},
        {x = 0, y = 0, width = 200, height = 50, label = "Quitter", action = function() 
            Transitions:start("fade", 0.5)
            love.event.quit()
        end}
    }
    self:updateButtonPositions()
end

function MenuState:updateButtonPositions()
    local scale = _G.gameConfig.scale
    local windowWidth = _G.gameConfig.windowWidth
    local windowHeight = _G.gameConfig.windowHeight
    
    local buttonWidth = 200 * scale
    local buttonHeight = 50 * scale
    local spacing = 20 * scale
    
    local totalHeight = #self.buttons * buttonHeight + (#self.buttons - 1) * spacing
    local startY = (windowHeight - totalHeight) / 2
    
    for i, button in ipairs(self.buttons) do
        button.width = buttonWidth
        button.height = buttonHeight
        button.x = (windowWidth - buttonWidth) / 2
        button.y = startY + (i - 1) * (buttonHeight + spacing)
    end
end

function MenuState:update(dt)
end

function MenuState:draw()
    love.graphics.clear(0.1, 0.1, 0.1)
    
    local scale = _G.gameConfig.scale
    local windowWidth = _G.gameConfig.windowWidth
    
    -- Titre
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(48 * scale))
    love.graphics.printf("La Vengeance de Pedro", 0, 50 * scale, windowWidth, "center")
    
    -- Boutons
    for i, button in ipairs(self.buttons) do
        if i == self.selectedButton then
            love.graphics.setColor(0.3, 0.5, 0.8)
        else
            love.graphics.setColor(0.2, 0.2, 0.2)
        end
        
        love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(24 * scale))
        love.graphics.printf(button.label, button.x, button.y + button.height / 4, button.width, "center")
    end
end

function MenuState:keypressed(key)
    if key == "up" or key == "z" then
        self.selectedButton = self.selectedButton - 1
        if self.selectedButton < 1 then
            self.selectedButton = #self.buttons
        end
    elseif key == "down" or key == "s" then
        self.selectedButton = self.selectedButton + 1
        if self.selectedButton > #self.buttons then
            self.selectedButton = 1
        end
    elseif key == "return" or key == "space" then
        self.buttons[self.selectedButton].action()
    end
end

function MenuState:mousepressed(x, y, button)
    for i, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.width and
           y >= btn.y and y <= btn.y + btn.height then
            btn.action()
            break
        end
    end
end

function MenuState:onResize()
    self:updateButtonPositions()
end

return MenuState