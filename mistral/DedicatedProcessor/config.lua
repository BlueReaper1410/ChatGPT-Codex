-- DedicatedProcessor - Configuration System
-- Handles all mod settings with persistence

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
        greetDelay = 5.0, -- seconds
        customMessageEnabled = false,
        customMessage = "Welcome to the server!",
        customMessageInterval = 300.0, -- 5 minutes
        lastCustomMessageTime = 0
    },
    
    -- Cleanup settings (DedicatedCleanup)
    cleanup = {
        enabled = true,
        subtleMessagesEnabled = true,
        cleanupIntervalMin = 30, -- minimum seconds between cleanups
        cleanupIntervalMax = 90, -- maximum seconds between cleanups
        lastCleanupTime = 0,
        structuresRemoved = 0
    },
    
    -- UI settings
    ui = {
        showStatusMessages = true,
        menuPosition = {x = 0.5, y = 0.5},
        menuScale = 1.0
    }
}

----------------------------------------------------------------------
-- Configuration storage
----------------------------------------------------------------------

local config = utils.deepCopy(DEFAULT_CONFIG)
local configLoaded = false
local configFilePath = "DedicatedProcessor_config.json"

----------------------------------------------------------------------
-- Configuration loading and saving
----------------------------------------------------------------------

-- Load configuration from file
local function loadConfig()
    local file = io.open(configFilePath, "r")
    if file then
        local content = file:read("*a")
        file:close()
        
        -- Simple JSON parsing (Trailmakers Lua doesn't have built-in JSON)
        -- We'll use a basic approach that works for our simple config
        local success, loadedConfig = pcall(function()
            -- Try to parse as Lua table (if saved as Lua)
            local chunk = loadstring("return " .. content)
            if chunk then
                return chunk()
            end
            return nil
        end)
        
        if success and loadedConfig and type(loadedConfig) == "table" then
            config = utils.mergeTables(DEFAULT_CONFIG, loadedConfig)
            utils.sendSuccessMessage("Configuration loaded", "Config")
        else
            -- Fallback to defaults
            config = utils.deepCopy(DEFAULT_CONFIG)
            utils.sendErrorMessage("Failed to load config, using defaults", "Config")
        end
    else
        -- Create default config file
        config = utils.deepCopy(DEFAULT_CONFIG)
        saveConfig()
    end
    
    configLoaded = true
end

-- Save configuration to file
function saveConfig()
    local file = io.open(configFilePath, "w")
    if file then
        -- Save as Lua table (easier than implementing full JSON serializer)
        local content = serialize(config)
        file:write(content)
        file:close()
        utils.sendSuccessMessage("Configuration saved", "Config")
    else
        utils.sendErrorMessage("Failed to save config", "Config")
    end
end

-- Simple serializer for Lua tables
local function serialize(tbl, indent)
    indent = indent or 0
    local str = ""
    local indentStr = string.rep("  ", indent)
    
    str = str .. "{\n"
    
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys)
    
    for i, k in ipairs(keys) do
        local v = tbl[k]
        str = str .. indentStr .. "  [" .. quote(tostring(k)) .. "] = "
        
        if type(v) == "table" then
            str = str .. serialize(v, indent + 2)
        elseif type(v) == "string" then
            str = str .. quote(v)
        elseif type(v) == "boolean" then
            str = str .. (v and "true" or "false")
        elseif type(v) == "number" then
            str = str .. tostring(v)
        else
            str = str .. "nil"
        end
        
        if i < #keys then
            str = str .. ","
        end
        str = str .. "\n"
    end
    
    str = str .. indentStr .. "}"
    return str
end

local function quote(str)
    return '"' .. string.gsub(tostring(str), '"', '\\"') .. '"'
end

----------------------------------------------------------------------
-- Configuration accessors
----------------------------------------------------------------------

-- Get the entire config
function getConfig()
    if not configLoaded then
        loadConfig()
    end
    return config
end

-- Get a specific config value
function getConfigValue(path)
    if not configLoaded then
        loadConfig()
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

-- Set a specific config value
function setConfigValue(path, value)
    if not configLoaded then
        loadConfig()
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
    saveConfig()
end

-- Toggle a boolean config value
function toggleConfigValue(path)
    local currentValue = getConfigValue(path)
    if type(currentValue) == "boolean" then
        setConfigValue(path, not currentValue)
        return not currentValue
    end
    return false
end

----------------------------------------------------------------------
-- Module initialization
----------------------------------------------------------------------

-- Load config on module load
loadConfig()

----------------------------------------------------------------------
-- Export configuration functions
----------------------------------------------------------------------

return {
    getConfig = getConfig,
    getConfigValue = getConfigValue,
    setConfigValue = setConfigValue,
    toggleConfigValue = toggleConfigValue,
    saveConfig = saveConfig,
    loadConfig = loadConfig,
    DEFAULT_CONFIG = DEFAULT_CONFIG
}
