local Mob = require("dungeon.mobs.mob")
local Traider = setmetatable({}, {__index = Mob})
local Medic =require("dungeon.masks.medic")
local Anonymous =require("dungeon.masks.anonymous")
local Paladin = require("dungeon.masks.paladin")

Traider.__index = Traider

function Traider:new(data)
    data.category = "normal"
    data.subtype = "traider"
    data.speed = 0
    data.size = 70
    data.maxHP = 100000
    data.damage = 0
    data.dropChance = 0

    local m = Mob.new(self, data)
    m.relX = data.relX or 0.5
    m.relY = data.relY or 0.5

    m.attackCooldown = 9999
    m.attackTimer = 0
    m.dir = 0
    m.isImmobile = true
    m.state = "underground"

    m.image = love.graphics.newImage("dungeon/mobs/traider/assets/possu.png")

    m.drawLayer = "background"
    m.ignoreCollision = true
    m.shopOpen = false
    m.deltaShopClose = 0
    m.shopItems = {
        Paladin,
        Anonymous,
        Medic,
    }


    m.selectedItem = 1 -- Item sélectionné par défaut

    return m
end

-- Collision pixels
function Traider:checkCollision(player, ctx)
    local traiderX = ctx.roomX + self.relX * ctx.roomWidth
    local traiderY = ctx.roomY + self.relY * ctx.roomHeight

    local dx = traiderX - player.x
    local dy = traiderY - player.y
    local distance = math.sqrt(dx*dx + dy*dy)

    return distance < self.size
end

function Traider:update(dt, ctx)
    local player = ctx.player
    if not player then return end

    if self:checkCollision(player, ctx) and not self.shopOpen and self.deltaShopClose == 0 then
        self.shopOpen = true
        player.isImmobile = true  -- Bloquer le joueur dès l'ouverture du shop
    end

    if love.keyboard.isDown(_G.gameConfig.keys.escape) then
        self.shopOpen = false
        player.isImmobile = false
        self.deltaShopClose = 20
    end
    if self.deltaShopClose > 0 then
        self.deltaShopClose = self.deltaShopClose - 1
    end
end

function Traider:draw(ctx)
    local x = ctx.roomX + self.relX * ctx.roomWidth
    local y = ctx.roomY + self.relY * ctx.roomHeight

    if self.image then
        love.graphics.setColor(1, 1, 1)
        local img = self.image
        local imgWidth = img:getWidth()
        local imgHeight = img:getHeight()
        local scaleX = self.size * 2 / imgWidth
        local scaleY = self.size * 2 / imgHeight
        love.graphics.draw(img, x, y, 0, scaleX, scaleY, imgWidth/2, imgHeight/2)
    end

    if self.shopOpen then
        self:drawShop()
    end
end

function Traider:drawShop()
    local width = 250
    local height = 200
    local x = 300
    local y = 150

    -- Fond
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", x, y, width, height, 10, 10)

    -- Bordure
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, width, height, 10, 10)

    love.graphics.setNewFont(14)
    local padding = 10
    local lineHeight = 25

    love.graphics.print("SHOP DU MARCHAND", x + padding, y + padding)

    -- Boucle sur les items du shop
    for i, itemClass in ipairs(self.shopItems) do
        local item = itemClass:new()
        local color = (i == self.selectedItem) and {1,1,0} or {1,1,1}
        love.graphics.setColor(color)

        -- Fallback local pour le name
        local itemName = item.name or "Masque"
        love.graphics.print(itemName, x + padding, y + padding + i * lineHeight)
    end

end

-- Sélectionner item avec les touches
function Traider:shopKeypressed(key, player)
    if not self.shopOpen then return end

    if key == "up" then
        self.selectedItem = self.selectedItem - 1
        if self.selectedItem < 1 then self.selectedItem = #self.shopItems end
    elseif key == "down" then
        self.selectedItem = self.selectedItem + 1
        if self.selectedItem > #self.shopItems then self.selectedItem = 1 end
    elseif key == "return" then
        -- Acheter l'item
        local itemClass = self.shopItems[self.selectedItem]
        local newMask = itemClass:new()

        -- Fallback local pour le name
        if not newMask.name then
            newMask.name = "Masque"
        end

        player.maskManager:startPickup(newMask)

        -- Fermer le shop et débloquer le joueur
        self.shopOpen = false
        player.isImmobile = false
    elseif key == "escape" then
        -- Fermer le shop sans acheter
        self.shopOpen = false
        player.isImmobile = false
    end
end

return Traider
