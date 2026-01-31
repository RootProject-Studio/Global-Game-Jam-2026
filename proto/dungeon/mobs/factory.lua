local factory = {}

factory.normal = {
    slime   = require("dungeon.mobs.normal.slime"),
    --bat     = require("dungeon.mobs.normal.bat"),
    --charger = require("dungeon.mobs.normal.charger"),
}

factory.boss = {
    guardian = require("dungeon.mobs.boss.DaftPunk"),
    --brute    = require("dungeon.mobs.boss.brute"),
}

function factory.create(category, subtype, data)
    return factory[category][subtype]:new(data)
end

return factory
