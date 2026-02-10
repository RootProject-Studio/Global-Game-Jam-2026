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
    data.size = 140
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
    m.shopVideoPath = "videos/shop.ogv"
    m.shopVideo = nil
    m.shopVideoLoaded = false
    m.shopVideoStarted = false
    m.shopVideoCanvas = nil
    m.shopVideoShader = love.graphics.newShader([[
        extern vec3 keyColor;
        extern number threshold;
        extern number smoothing;

        vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
        {
            vec4 pixel = Texel(tex, tc) * color;
            number dist = distance(pixel.rgb, keyColor);
            number alpha = smoothstep(threshold, threshold + smoothing, dist);
            pixel.a = pixel.a * alpha;
            return pixel;
        }
    ]])
    m.shopItems = {
        Paladin,
        Anonymous,
        Medic,
    }
    m.visualSize = 260
    m.baseVisualSize = m.visualSize


    m.selectedItem = 1 -- Item sélectionné par défaut

    return m
end

function Traider:applyScale(scale)
    if not scale then return end
    if Mob.applyScale then
        Mob.applyScale(self, scale)
    end
    if self.baseVisualSize then
        self.visualSize = self.baseVisualSize * scale
    end
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
        self:closeShop(player)
    end
    if self.deltaShopClose > 0 then
        self.deltaShopClose = self.deltaShopClose - 1
    end

    if self.shopOpen then
        self:ensureShopVideo()
        if self.shopVideo and not self.shopVideoStarted then
            self.shopVideo:play()
            self.shopVideoStarted = true
        end
    elseif self.shopVideo and self.shopVideo:isPlaying() then
        self.shopVideo:pause()
        self.shopVideo:rewind()
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
        local targetSize = self.visualSize or (self.size * 2)
        local scaleX = targetSize / imgWidth
        local scaleY = targetSize / imgHeight
        love.graphics.draw(img, x, y, 0, scaleX, scaleY, imgWidth/2, imgHeight/2)
    end

    if self.shopOpen then
        self:drawShop()
    end
end

function Traider:drawShop()
    local scale = _G.gameConfig.scale or math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    local width = 250 * scale
    local height = 200 * scale
    local x = (_G.gameConfig.windowWidth - width) / 2
    local y = (_G.gameConfig.windowHeight - height) / 2

    -- Fond
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", x, y, width, height, 10, 10)

    -- Bordure
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, width, height, 10, 10)

    love.graphics.setNewFont(14 * scale)
    local padding = 10 * scale
    local lineHeight = 25 * scale

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

    if self.shopVideo then
        local videoWidth = self.shopVideo:getWidth()
        local videoHeight = self.shopVideo:getHeight()
        local maxWidth = 260 * scale
        local maxHeight = height
        local scale = math.min(maxWidth / videoWidth, maxHeight / videoHeight, 1)
        local drawWidth = videoWidth * scale
        local drawHeight = videoHeight * scale

        local videoX = x - drawWidth - 20 * scale
        local videoY = y
        if videoX < 10 then
            videoX = x + width + 20 * scale
        end
        if videoX + drawWidth > _G.gameConfig.windowWidth then
            videoX = _G.gameConfig.windowWidth - drawWidth - 10 * scale
        end
        if videoY + drawHeight > _G.gameConfig.windowHeight then
            videoY = _G.gameConfig.windowHeight - drawHeight - 10 * scale
        end

        if self.shopVideoCanvas then
            local previousCanvas = love.graphics.getCanvas()
            love.graphics.setCanvas(self.shopVideoCanvas)
            love.graphics.clear(0, 0, 0, 0)
            love.graphics.setShader()
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(self.shopVideo, 0, 0)
            love.graphics.setCanvas(previousCanvas)

            love.graphics.setColor(1, 1, 1)
            love.graphics.setShader(self.shopVideoShader)
            self.shopVideoShader:send("keyColor", {0.0, 1.0, 0.0})
            self.shopVideoShader:send("threshold", 0.35)
            self.shopVideoShader:send("smoothing", 0.1)
            love.graphics.draw(self.shopVideoCanvas, videoX, videoY, 0, scale, scale)
            love.graphics.setShader()
        end
    end

end

function Traider:ensureShopVideo()
    if self.shopVideoLoaded then return end
    self.shopVideoLoaded = true

    if love.filesystem.getInfo(self.shopVideoPath) then
        local ok, videoOrErr = pcall(love.graphics.newVideo, self.shopVideoPath)
        if ok then
            self.shopVideo = videoOrErr
            self.shopVideoCanvas = love.graphics.newCanvas(self.shopVideo:getWidth(), self.shopVideo:getHeight())
            self.shopVideoStarted = false
        else
            io.stderr:write("Shop video invalid or unsupported: " .. tostring(videoOrErr) .. "\n")
        end
    end
end

function Traider:closeShop(player)
    self.shopOpen = false
    player.isImmobile = false
    self.deltaShopClose = 20

    if self.shopVideo and self.shopVideo:isPlaying() then
        self.shopVideo:pause()
        self.shopVideo:rewind()
    end
    self.shopVideoStarted = false
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
        self:closeShop(player)
    elseif key == "escape" then
        -- Fermer le shop sans acheter
        self:closeShop(player)
    end
end

return Traider
