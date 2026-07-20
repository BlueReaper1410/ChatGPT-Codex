-- DedicatedProcessor - Chat Module
-- Handles player greetings and custom chat messages for Trailmakers

local utils = require("utils")
local config = require("config")

----------------------------------------------------------------------
-- State
----------------------------------------------------------------------

local pendingGreetings = {}
local lastCustomMessageTime = 0

----------------------------------------------------------------------
-- Chat functionality
----------------------------------------------------------------------

local function GreetPlayer(playerId)
    if not config.GetConfigValue("chat.greetNewPlayers") then
        return
    end
    
    local name = utils.GetPlayerName(playerId)
    local message = "Welcome, " .. name .. "!"
    utils.SendChatMessage(utils.CHAT_NAME, message, utils.CHAT_COLOR)
end

local function BroadcastCustomMessage()
    if not config.GetConfigValue("chat.customMessageEnabled") then
        return
    end
    
    local customMessage = config.GetConfigValue("chat.customMessage")
    if customMessage and customMessage ~= "" then
        utils.SendChatMessage(utils.CHAT_NAME, customMessage, utils.CHAT_COLOR)
        lastCustomMessageTime = tm.os.GetTime()
        config.SetConfigValue("chat.lastCustomMessageTime", lastCustomMessageTime)
    end
end

function SendCustomChatMessage(message)
    if message and message ~= "" then
        utils.SendChatMessage(utils.CHAT_NAME, message, utils.CHAT_COLOR)
        config.SetConfigValue("chat.customMessage", message)
        config.SetConfigValue("chat.customMessageEnabled", true)
    end
end

----------------------------------------------------------------------
-- Event handlers
----------------------------------------------------------------------

function OnPlayerJoined(player)
    utils.safeCall("Chat.OnPlayerJoined", function()
        if not utils.IsValidPlayer(player) then
            return
        end
        
        if config.GetConfigValue("chat.greetNewPlayers") then
            pendingGreetings[player.playerId] = tm.os.GetTime() + (config.GetConfigValue("chat.greetDelay") or 5.0)
        end
    end)
end

function OnPlayerLeft(player)
    utils.safeCall("Chat.OnPlayerLeft", function()
        if not utils.IsValidPlayer(player) then
            return
        end
        pendingGreetings[player.playerId] = nil
    end)
end

----------------------------------------------------------------------
-- Update function
----------------------------------------------------------------------

function Update()
    utils.safeCall("Chat.Update", function()
        local now = tm.os.GetTime()
        
        -- Process pending greetings
        local toClear = {}
        for playerId, greetTime in pairs(pendingGreetings) do
            if now >= greetTime then
                GreetPlayer(playerId)
                table.insert(toClear, playerId)
            end
        end
        for _, playerId in ipairs(toClear) do
            pendingGreetings[playerId] = nil
        end
        
        -- Check for custom message broadcast
        local customInterval = config.GetConfigValue("chat.customMessageInterval") or 300.0
        if customInterval > 0 and now >= (lastCustomMessageTime + customInterval) then
            BroadcastCustomMessage()
        end
    end)
end

----------------------------------------------------------------------
-- Module initialization
----------------------------------------------------------------------

-- Register event handlers
utils.safeCall("Chat registration", function()
    tm.players.OnPlayerJoined.add(OnPlayerJoined)
    tm.players.OnPlayerLeft.add(OnPlayerLeft)
end)

----------------------------------------------------------------------
-- Export chat functions
----------------------------------------------------------------------

return {
    Update = Update,
    SendCustomChatMessage = SendCustomChatMessage,
    OnPlayerJoined = OnPlayerJoined,
    OnPlayerLeft = OnPlayerLeft
}
