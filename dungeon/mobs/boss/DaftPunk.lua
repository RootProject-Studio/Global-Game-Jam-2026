local Mob = require("dungeon.mobs.mob")
local Guardian = setmetatable({}, Mob)
Guardian.__index = Guardian

function Guardian:new(data)
    data.category = "boss"
    data.subtype = "guardian"
    data.speed = 20
    data.size = 36

    local m = Mob.new(self, data)
    m.angle = 0
    m.image = nil
    m.imagePath = "dungeon/mobs/boss/assets/kangourou.png"
    if love.filesystem.getInfo(m.imagePath) then
        m.image = love.graphics.newImage(m.imagePath)
    end
    return m
end

function Guardian:update(dt, ctx)
    self.angle = self.angle + dt
    self.relX = 0.5 + math.cos(self.angle) * 0.2
    self.relY = 0.5 + math.sin(self.angle) * 0.2
end

function Guardian:draw(ctx)
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    if self.image then
        love.graphics.setColor(1, 1, 1)
        local imgWidth = self.image:getWidth()
        local imgHeight = self.image:getHeight()
        local targetSize = self.size * 2
        local scaleX = targetSize / imgWidth
        local scaleY = targetSize / imgHeight
        love.graphics.draw(self.image, x, y, 0, scaleX, scaleY, imgWidth / 2, imgHeight / 2)
    else
        love.graphics.setColor(1, 0, 0)
        love.graphics.circle("fill", x, y, self.size)
    end
end

return Guardian
