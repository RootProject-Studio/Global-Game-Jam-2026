-- transitions.lua
-- Gestionnaire de transitions entre les états

local Transitions = {
    active = false,
    progress = 0,
    duration = 0.5,
    type = "fade", -- "fade", "slideLeft", "slideRight", "slideUp", "slideDown"
    direction = "out" -- "in" (entrée), "out" (sortie)
}

function Transitions:start(transitionType, duration)
    self.active = true
    self.progress = 0
    self.duration = duration or 0.5
    self.type = transitionType or "fade"
    self.direction = "out"
end

function Transitions:update(dt)
    if self.active then
        self.progress = self.progress + dt / self.duration
        if self.progress >= 1 then
            self.progress = 1
            self.active = false
            return true -- Transition terminée
        end
    end
    return false
end

function Transitions:draw()
    if self.progress == 0 then return end

    local progress = self.progress
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()

    if self.type == "fade" then
        love.graphics.setColor(0, 0, 0, progress)
        love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
        love.graphics.setColor(1, 1, 1, 1)

    elseif self.type == "slideLeft" then
        love.graphics.setColor(0, 0, 0, 1)
        local offset = windowWidth * progress
        love.graphics.rectangle("fill", offset, 0, windowWidth, windowHeight)
        love.graphics.setColor(1, 1, 1, 1)

    elseif self.type == "slideRight" then
        love.graphics.setColor(0, 0, 0, 1)
        local offset = -windowWidth * progress
        love.graphics.rectangle("fill", offset, 0, windowWidth, windowHeight)
        love.graphics.setColor(1, 1, 1, 1)

    elseif self.type == "slideUp" then
        love.graphics.setColor(0, 0, 0, 1)
        local offset = windowHeight * progress
        love.graphics.rectangle("fill", 0, offset, windowWidth, windowHeight)
        love.graphics.setColor(1, 1, 1, 1)

    elseif self.type == "slideDown" then
        love.graphics.setColor(0, 0, 0, 1)
        local offset = -windowHeight * progress
        love.graphics.rectangle("fill", 0, offset, windowWidth, windowHeight)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return Transitions