-- gamestate.lua
-- Gestionnaire d'états du jeu

local GameStateManager = {
    currentState = nil,
    states = {}
}

function GameStateManager:init()
    self.currentState = nil
    self.states = {}
end

function GameStateManager:registerState(name, state)
    self.states[name] = state
end

function GameStateManager:setState(name)
    -- Appeler la fonction exit de l'état actuel s'il existe
    if self.currentState and self.currentState.exit then
        self.currentState:exit()
    end
    
    -- Changer d'état
    self.currentState = self.states[name]
    
    -- Appeler la fonction enter du nouvel état
    if self.currentState and self.currentState.enter then
        self.currentState:enter()
    end
end

function GameStateManager:update(dt)
    if self.currentState and self.currentState.update then
        self.currentState:update(dt)
    end
end

function GameStateManager:draw()
    if self.currentState and self.currentState.draw then
        self.currentState:draw()
    end
end

function GameStateManager:keypressed(key)
    if self.currentState and self.currentState.keypressed then
        self.currentState:keypressed(key)
    end
end

function GameStateManager:mousepressed(x, y, button)
    if self.currentState and self.currentState.mousepressed then
        self.currentState:mousepressed(x, y, button)
    end
end

function GameStateManager:onResize()
    if self.currentState and self.currentState.onResize then
        self.currentState:onResize()
    end
end

return GameStateManager