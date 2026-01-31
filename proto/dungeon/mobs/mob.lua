local Mob = {}
Mob.__index = Mob

function Mob:new(data)
    local m = setmetatable({}, self)

    m.category = data.category      -- "normal" | "boss"
    m.subtype  = data.subtype       -- "slime", "guardian", etc

    -- position relative (0 → 1)
    m.relX = data.relX or 0.5
    m.relY = data.relY or 0.5

    m.speed = data.speed or 40
    m.size  = data.size  or 15

    return m
end

function Mob:update(dt, ctx)
    -- redéfini dans les sous-types
end

function Mob:draw(ctx)
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    love.graphics.circle("fill", x, y, self.size * ctx.scale)
end

return Mob
