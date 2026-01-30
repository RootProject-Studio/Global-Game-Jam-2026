local GameStateManager = require("gamestate")
local Transitions = require("transitions")
local MenuState = require("states.menu")
local CreditsState = require("states.credits")
local OptionsState = require("states.options")

function love.load()
    -- Configuration de la fenêtre
    love.window.setTitle("La Vengeance de Pedro")
    love.window.setMode(800, 600, {
        resizable = true,
        vsync = true
    })

    -- Initialiser la configuration globale du jeu avec dimensions responsives
    _G.gameConfig = {
        -- Dimensions de base pour le calcul des proportions
        baseWidth = 800,
        baseHeight = 600,
        -- Dimensions actuelles de la fenêtre
        windowWidth = 800,
        windowHeight = 600,
        -- Facteurs d'échelle
        scaleX = 1.0,
        scaleY = 1.0,

        keys = {
            up = "z",
            down = "s",
            left = "q",
            right = "d",
            shoot_up = "up",
            shoot_down = "down",
            shoot_left = "left",
            shoot_right = "right",
        }
    }

    -- Mettre à jour l'échelle initiale
    updateGameScale()

    -- Initialisation du gestionnaire d'états
    GameStateManager:init()

    -- Enregistrement des états
    GameStateManager:registerState("menu", MenuState)
    -- GameStateManager:registerState("game", GameState)
    GameStateManager:registerState("options", OptionsState)
    GameStateManager:registerState("credits", CreditsState)

    -- Démarrage avec le menu
    GameStateManager:setState("menu")
end

function love.update(dt)
    GameStateManager:update(dt)
    Transitions:update(dt)
end

function love.draw()
    GameStateManager:draw()
    Transitions:draw()
end

function love.keypressed(key)
    GameStateManager:keypressed(key)
end

function love.mousepressed(x, y, button)
    GameStateManager:mousepressed(x, y, button)
end

-- Fonction pour mettre à jour l'échelle en fonction de la taille de la fenêtre
function updateGameScale()
    _G.gameConfig.windowWidth = love.graphics.getWidth()
    _G.gameConfig.windowHeight = love.graphics.getHeight()

    -- Calculer les facteurs d'échelle
    _G.gameConfig.scaleX = _G.gameConfig.windowWidth / _G.gameConfig.baseWidth
    _G.gameConfig.scaleY = _G.gameConfig.windowHeight / _G.gameConfig.baseHeight

    -- Utiliser l'échelle minimale pour éviter un zoom excessif
    -- Et maintenir des proportions correctes
    local minScale = math.min(_G.gameConfig.scaleX, _G.gameConfig.scaleY)
    _G.gameConfig.scale = minScale
end

-- Gestion du redimensionnement de la fenêtre
function love.resize(w, h)
    updateGameScale()
    GameStateManager:onResize()
end

-- Fonction utilitaire pour changer d'état avec transition
function transitionToState(stateName, transitionType, duration)
    Transitions:start(transitionType or "fade", duration or 0.5)
    -- Changer d'état après la moitié de la transition
    love.timer.sleep(0)
    GameStateManager:setState(stateName)
end