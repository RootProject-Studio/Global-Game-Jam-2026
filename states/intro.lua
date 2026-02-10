local GameStateManager = require("gamestate")
local AudioManager = require("audio_manager")

local IntroState = {
    video = nil,
    started = false,
    videoPath = "videos/intro.ogv"
}

function IntroState:enter()
    AudioManager:stopMusic()
    if not love.filesystem.getInfo(self.videoPath) then
        GameStateManager:setState("menu")
        return
    end

    local ok, videoOrErr = pcall(love.graphics.newVideo, self.videoPath)
    if not ok then
        io.stderr:write("Intro video invalid or unsupported: " .. tostring(videoOrErr) .. "\n")
        GameStateManager:setState("menu")
        return
    end

    self.video = videoOrErr
    self.video:play()
    self.started = true
end

function IntroState:update(dt)
    if self.video and self.started and not self.video:isPlaying() then
        GameStateManager:setState("menu")
    end
end

function IntroState:draw()
    love.graphics.clear(0, 0, 0)

    if not self.video then return end

    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    local videoWidth = self.video:getWidth()
    local videoHeight = self.video:getHeight()

    local scale = math.min(windowWidth / videoWidth, windowHeight / videoHeight)
    local drawWidth = videoWidth * scale
    local drawHeight = videoHeight * scale
    local x = (windowWidth - drawWidth) / 2
    local y = (windowHeight - drawHeight) / 2

    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.video, x, y, 0, scale, scale)
end

function IntroState:keypressed(key)
    if key == "space" then
        self:skip()
    end
end

function IntroState:skip()
    if self.video then
        self.video:pause()
        self.video:rewind()
    end
    GameStateManager:setState("menu")
end

function IntroState:exit()
    if self.video then
        self.video:pause()
        self.video:rewind()
    end
    self.video = nil
    self.started = false
end

return IntroState
