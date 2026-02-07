local factory = {}

factory.normal = {
    rat     = require("dungeon.mobs.normal.rat"),
    pigeon  = require("dungeon.mobs.normal.pigeon"),
    blaireau     = require("dungeon.mobs.normal.blaireau"),
    --charger = require("dungeon.mobs.normal.charger"),
}

factory.boss = {
    guardian = require("dungeon.mobs.boss.DaftPunk"),
    DarkVador = require("dungeon.mobs.boss.DarkVador"),
    TheMask  = require("dungeon.mobs.boss.TheMask"),
    Scarface = require("dungeon.mobs.boss.Scarface"),

    --brute    = require("dungeon.mobs.boss.brute"),
}

factory.shop = {
    traider = require("dungeon.mobs.traider.traider"),
}

function factory.create(category, subtype, data)
    return factory[category][subtype]:new(data)
end

return factory
