-- Utilitaire pour charger les configurations JSON

local ConfigLoader = {}

function ConfigLoader.loadJSON(filePath)
    -- Lire le fichier JSON en utilisant le système de fichiers LÖVE
    local content, err = love.filesystem.read(filePath)
    if not content then
        error("Impossible d'ouvrir le fichier: " .. filePath .. " (" .. tostring(err) .. ")")
        return nil
    end
    
    -- Parser JSON
    return ConfigLoader.parseJSON(content)
end

-- Parseur JSON simple (sans dépendance externe)
function ConfigLoader.parseJSON(jsonString)
    jsonString = jsonString:gsub("^%s+", ""):gsub("%s+$", "")
    
    local pos = 1
    
    local function skipWhitespace()
        while pos <= #jsonString and jsonString:sub(pos, pos):match("%s") do
            pos = pos + 1
        end
    end
    
    local function parseNumber()
        local startPos = pos
        
        if jsonString:sub(pos, pos) == "-" then
            pos = pos + 1
        end
        
        while pos <= #jsonString and jsonString:sub(pos, pos):match("[0-9.]") do
            pos = pos + 1
        end
        
        local numStr = jsonString:sub(startPos, pos - 1)
        return tonumber(numStr)
    end
    
    local function parseString()
        pos = pos + 1 -- Skip "
        local str = ""
        
        while pos <= #jsonString do
            local char = jsonString:sub(pos, pos)
            
            if char == '"' then
                pos = pos + 1
                return str
            elseif char == "\\" then
                pos = pos + 1
                local escaped = jsonString:sub(pos, pos)
                if escaped == "n" then
                    str = str .. "\n"
                elseif escaped == "t" then
                    str = str .. "\t"
                elseif escaped == "r" then
                    str = str .. "\r"
                elseif escaped == '"' then
                    str = str .. '"'
                elseif escaped == "\\" then
                    str = str .. "\\"
                else
                    str = str .. escaped
                end
            else
                str = str .. char
            end
            pos = pos + 1
        end
        
        error("Unterminated string in JSON")
    end
    
    local parseValue, parseObject, parseArray
    
    function parseValue()
        skipWhitespace()
        local char = jsonString:sub(pos, pos)
        
        if char == "{" then
            return parseObject()
        elseif char == "[" then
            return parseArray()
        elseif char == '"' then
            return parseString()
        elseif char == "t" then
            pos = pos + 4
            return true
        elseif char == "f" then
            pos = pos + 5
            return false
        elseif char == "n" then
            pos = pos + 4
            return nil
        else
            return parseNumber()
        end
    end
    
    function parseObject()
        pos = pos + 1 -- Skip {
        local obj = {}
        skipWhitespace()
        
        if jsonString:sub(pos, pos) == "}" then
            pos = pos + 1
            return obj
        end
        
        while true do
            skipWhitespace()
            local key = parseString()
            skipWhitespace()
            
            if jsonString:sub(pos, pos) ~= ":" then
                error("Expected ':' in JSON object")
            end
            pos = pos + 1
            
            local value = parseValue()
            obj[key] = value
            skipWhitespace()
            
            local char = jsonString:sub(pos, pos)
            if char == "}" then
                pos = pos + 1
                break
            elseif char == "," then
                pos = pos + 1
            else
                error("Expected ',' or '}' in JSON object")
            end
        end
        
        return obj
    end
    
    function parseArray()
        pos = pos + 1 -- Skip [
        local arr = {}
        skipWhitespace()
        
        if jsonString:sub(pos, pos) == "]" then
            pos = pos + 1
            return arr
        end
        
        local index = 1
        while true do
            local value = parseValue()
            arr[index] = value
            index = index + 1
            skipWhitespace()
            
            local char = jsonString:sub(pos, pos)
            if char == "]" then
                pos = pos + 1
                break
            elseif char == "," then
                pos = pos + 1
            else
                error("Expected ',' or ']' in JSON array")
            end
        end
        
        return arr
    end
    
    return parseValue()
end

function ConfigLoader.getMaskConfig(maskName)
    -- Charger la configuration depuis le JSON
    local configPath = "dungeon/masks/masks_config.json"
    local config = ConfigLoader.loadJSON(configPath)
    return config[maskName]
end

return ConfigLoader
