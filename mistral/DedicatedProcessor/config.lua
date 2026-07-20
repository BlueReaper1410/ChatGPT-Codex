-- DedicatedProcessor - Configuration System
-- Handles all mod settings with persistence for Trailmakers

local utils = require("utils")

----------------------------------------------------------------------
-- Default configuration
----------------------------------------------------------------------

local DEFAULT_CONFIG = {
    -- General settings
    modEnabled = true,
    
    -- Chat settings
    chat = {
        enabled = true,
        greetNewPlayers = true,
        greetDelay = 5.0,
        customMessageEnabled = false,
        customMessage = "Welcome to the server!",
        customMessageInterval = 300.0,
        lastCustomMessageTime = 0
    },
    
    -- Cleanup settings (DedicatedCleanup)
    cleanup = {
        enabled = true,
        subtleMessagesEnabled = true,
        cleanupIntervalMin = 30,
        cleanupIntervalMax = 90,
        lastCleanupTime = 0,
        structuresRemoved = 0
    },
    
    -- UI settings
    ui = {
        showStatusMessages = true
    }
}

----------------------------------------------------------------------
-- Configuration storage
----------------------------------------------------------------------

local config = utils.deepCopy(DEFAULT_CONFIG)
local configLoaded = false
local configFilePath = "DedicatedProcessor_config.txt"

----------------------------------------------------------------------
-- Simple serialization for Trailmakers
----------------------------------------------------------------------

local function serializeTable(tbl, indent)
    indent = indent or 0
    local indentStr = string.rep("  ", indent)
    local lines = {}
    
    table.insert(lines, indentStr .. "{")
    
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys)
    
    for i, k in ipairs(keys) do
        local v = tbl[k]
        local keyStr = "[" .. tostring(k) .. "]"
        
        if type(v) == "table" then
            local subLines = {}
            table.insert(subLines, serializeTable(v, indent + 1))
            table.insert(lines, indentStr .. "  " .. keyStr .. " = " .. table.concat(subLines, ","))
        elseif type(v) == "string" then
            table.insert(lines, indentStr .. "  " .. keyStr .. " = \"" .. string.gsub(v, "\\", "\\\\").. "\"")
        elseif type(v) == "boolean" then
            table.insert(lines, indentStr .. "  " .. keyStr .. " = " .. (v and "true" or "false"))
        elseif type(v) == "number" then
            table.insert(lines, indentStr .. "  " .. keyStr .. " = " .. tostring(v))
        else
            table.insert(lines, indentStr .. "  " .. keyStr .. " = nil")
        end
        
        if i < #keys then
            lines[#lines] = lines[#lines] .. ","
        end
    end
    
    table.insert(lines, indentStr .. "}")
    return table.concat(lines, "\n")
end

local function deserializeTable(str)
    -- Simple parser for our format
    local result = {}
    local current = result
    local stack = {result}
    local i = 1
    local len = #str
    
    while i <= len do
        -- Skip whitespace
        while i <= len and (str:sub(i,i) == " " or str:sub(i,i) == "\n" or str:sub(i,i) == "\t") do
            i = i + 1
        end
        
        if i > len then break end
        
        -- Check for closing brace
        if str:sub(i,i) == "}" then
            table.remove(stack)
            current = stack[#stack]
            i = i + 1
        -- Check for opening brace
        elseif str:sub(i,i) == "{" then
            i = i + 1
        -- Check for key
        elseif str:sub(i,i) == "[" then
            local j = i + 1
            while j <= len and str:sub(j,j) ~= "]" do
                j = j + 1
            end
            local key = str:sub(i+1, j-1)
            i = j + 1
            
            -- Skip to equals
            while i <= len and str:sub(i,i) ~= "=" do
                i = i + 1
            end
            i = i + 1
            
            -- Skip whitespace
            while i <= len and (str:sub(i,i) == " " or str:sub(i,i) == "\t") do
                i = i + 1
            end
            
            -- Get value
            local value
            if str:sub(i,i) == "\"" then
                -- String
                local j = i + 1
                while j <= len and str:sub(j,j) ~= "\"" do
                    j = j + 1
                end
                value = str:sub(i+1, j-1)
                i = j + 1
            elseif str:sub(i,i) == "t" then
                -- true
                value = true
                i = i + 4
            elseif str:sub(i,i) == "f" then
                -- false
                value = false
                i = i + 5
            elseif str:sub(i,i) == "n" then
                -- nil
                value = nil
                i = i + 3
            else
                -- Number
                local j = i
                while j <= len and (str:sub(j,j):match("%d") or str:sub(j,j) == "." or str:sub(j,j) == "-") do
                    j = j + 1
                end
                value = tonumber(str:sub(i, j-1))
                i = j
            end
            
            current[key] = value
            
            -- Check for comma
            while i <= len and (str:sub(i,i) == " " or str:sub(i,i) == "\t" or str:sub(i,i) == "\n") do
                i = i + 1
            end
            if i <= len and str:sub(i,i) == "," then
                i = i + 1
            end
        else
            i = i + 1
        end
    end
    
    return result
end

----------------------------------------------------------------------
-- Configuration loading and saving
----------------------------------------------------------------------

function LoadConfig()
    local file = io.open(configFilePath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        
        local success, loadedConfig = pcall(function()
            return deserializeTable(content)
        end)
        
        if success and loadedConfig and type(loadedConfig) == "table" then
            config = utils.mergeTables(DEFAULT_CONFIG, loadedConfig)
            utils.SendSuccessMessage("Configuration loaded", "Config")
        else
            config = utils.deepCopy(DEFAULT_CONFIG)
            utils.SendErrorMessage("Failed to load config, using defaults", "Config")
        end
    else
        config = utils.deepCopy(DEFAULT_CONFIG)
        SaveConfig()
    end
    
    configLoaded = true
end

function SaveConfig()
    local file = io.open(configFilePath, "w")
    if file then
        local content = serializeTable(config)
        file:write(content)
        file:close()
        utils.SendSuccessMessage("Configuration saved", "Config")
    else
        utils.SendErrorMessage("Failed to save config", "Config")
    end
end

----------------------------------------------------------------------
-- Configuration accessors
----------------------------------------------------------------------

function GetConfig()
    if not configLoaded then
        LoadConfig()
    end
    return config
end

function GetConfigValue(path)
    if not configLoaded then
        LoadConfig()
    end
    
    local current = config
    for part in string.gmatch(path, "[^.]+") do
        if current[part] == nil then
            return nil
        end
        current = current[part]
    end
    return current
end

function SetConfigValue(path, value)
    if not configLoaded then
        LoadConfig()
    end
    
    local current = config
    local parts = {}
    for part in string.gmatch(path, "[^.]+") do
        table.insert(parts, part)
    end
    
    for i = 1, #parts - 1 do
        local part = parts[i]
        if current[part] == nil then
            current[part] = {}
        end
        current = current[part]
    end
    
    current[parts[#parts]] = value
    SaveConfig()
end

function ToggleConfigValue(path)
    local currentValue = GetConfigValue(path)
    if type(currentValue) == "boolean" then
        SetConfigValue(path, not currentValue)
        return not currentValue
    end
    return false
end

----------------------------------------------------------------------
-- Module initialization
----------------------------------------------------------------------

LoadConfig()

----------------------------------------------------------------------
-- Export configuration functions
----------------------------------------------------------------------

return {
    GetConfig = GetConfig,
    GetConfigValue = GetConfigValue,
    SetConfigValue = SetConfigValue,
    ToggleConfigValue = ToggleConfigValue,
    SaveConfig = SaveConfig,
    LoadConfig = LoadConfig,
    DEFAULT_CONFIG = DEFAULT_CONFIG
}
