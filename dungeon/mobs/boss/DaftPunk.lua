local Mob = require("dungeon.mobs.mob")
local Guardian = setmetatable({}, Mob)
Guardian.__index = Guardian

function Guardian:new(data)
    data.category = "boss"
    data.subtype = "guardian"
    data.speed = 20
    data.size = 30

    local m = Mob.new(self, data)
    m.angle = 0
    return m
end

function Guardian:update(dt, ctx)
    self.angle = self.angle + dt
    self.relX = 0.5 + math.cos(self.angle) * 0.2
    self.relY = 0.5 + math.sin(self.angle) * 0.2
end

function Guardian:draw(ctx)
    love.graphics.setColor(0.9, 0.2, 0.2)
    Mob.draw(self, ctx)
end


function Guardian:draw(ctx)
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", x, y, self.size)
end

return Guardian
