local Mob = require("dungeon.mobs.mob")
local Traider = setmetatable({}, {__index = Mob})
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
    m.shopItems = {
        {name = "Potion", price = 10},
        {name = "Épée", price = 50},
        {name = "Bouclier", price = 30}
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

    if self:checkCollision(player, ctx) and not self.shopOpen then
        self.shopOpen = true
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

    for i, item in ipairs(self.shopItems) do
        if i == self.selectedItem then
            love.graphics.setColor(1, 1, 0) -- jaune pour l'item sélectionné
        else
            love.graphics.setColor(1, 1, 1)
        end
        love.graphics.print(item.name .. " - " .. item.price .. " pièces", x + padding, y + padding + i * lineHeight)
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
        self:buyItem(player)
    elseif key == "escape" then
        self.shopOpen = false
    end
end

function Traider:buyItem(player)
    local item = self.shopItems[self.selectedItem]
    if player.gold >= item.price then
        player.gold = player.gold - item.price
        -- Ajouter l’item à l’inventaire
        table.insert(player.inventory, item)
        print("Acheté : " .. item.name)
    else
        print("Pas assez d'or pour " .. item.name)
    end
end

function Traider:closeShop()
    self.shopOpen = false
end

return Traider
