local factory = {}

factory.normal = {
    slime   = require("dungeon.mobs.normal.slime"),
    rat     = require("dungeon.mobs.normal.rat"),
    pigeon  = require("dungeon.mobs.normal.pigeon"),
    --bat     = require("dungeon.mobs.normal.bat"),
    --charger = require("dungeon.mobs.normal.charger"),
}

factory.boss = {
    guardian = require("dungeon.mobs.boss.DaftPunk"),
    DarkVador = require("dungeon.mobs.boss.DarkVador"),
    TheMask  = require("dungeon.mobs.boss.TheMask"),

    --brute    = require("dungeon.mobs.boss.brute"),
}

function factory.create(category, subtype, data)
    return factory[category][subtype]:new(data)
end

return factory
