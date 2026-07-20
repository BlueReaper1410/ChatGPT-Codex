-- DedicatedProcessor - Chat Module
-- Handles player greetings and custom chat messages

local utils = require("utils")
local config = require("config")

----------------------------------------------------------------------
-- State
----------------------------------------------------------------------

-- playerId -> time (tm.os.GetTime()) at which the greeting should fire
local pendingGreetings = {}

-- Time of last custom message broadcast
local lastCustomMessageTime = 0

----------------------------------------------------------------------
-- Chat functionality
----------------------------------------------------------------------

-- Greet a player
local function greetPlayer(playerId)
    if not config.getConfigValue("chat.greetNewPlayers") then
        return
    end
    
    local name = utils.getPlayerName(playerId)
    local message = "Welcome, " .. name .. "!"
    
    utils.sendChatMessage(message, utils.CHAT_COLOR, utils.CHAT_NAME)
end

-- Broadcast custom message to all players
local function broadcastCustomMessage()
    if not config.getConfigValue("chat.customMessageEnabled") then
        return
    end
    
    local customMessage = config.getConfigValue("chat.customMessage")
    if customMessage and customMessage ~= "" then
        utils.sendChatMessage(customMessage, utils.CHAT_COLOR, utils.CHAT_NAME)
        lastCustomMessageTime = tm.os.GetTime()
        config.setConfigValue("chat.lastCustomMessageTime", lastCustomMessageTime)
    end
end

-- Send chat message from UI input
function sendCustomChatMessage(message)
    if message and message ~= "" then
        utils.sendChatMessage(message, utils.CHAT_COLOR, utils.CHAT_NAME)
        
        -- Save to config for persistence
        config.setConfigValue("chat.customMessage", message)
        config.setConfigValue("chat.customMessageEnabled", true)
    end
end

----------------------------------------------------------------------
-- Event handlers
----------------------------------------------------------------------

function onPlayerJoined(player)
    utils.safeCall("Chat.OnPlayerJoined", function()
        if not utils.isValidPlayer(player) then
            error("OnPlayerJoined called with no valid player/playerId")
        end
        
        if config.getConfigValue("chat.greetNewPlayers") then
            pendingGreetings[player.playerId] = tm.os.GetTime() + config.getConfigValue("chat.greetDelay")
        end
    end)
end

function onPlayerLeft(player)
    utils.safeCall("Chat.OnPlayerLeft", function()
        if not utils.isValidPlayer(player) then
            return
        end
        pendingGreetings[player.playerId] = nil
    end)
end

----------------------------------------------------------------------
-- Update function
----------------------------------------------------------------------

function update()
    utils.safeCall("Chat.update", function()
        local now = tm.os.GetTime()
        
        -- Process pending greetings
        local toClear = {}
        for playerId, greetTime in pairs(pendingGreetings) do
            if now >= greetTime then
                greetPlayer(playerId)
                table.insert(toClear, playerId)
            end
        end
        for _, playerId in ipairs(toClear) do
            pendingGreetings[playerId] = nil
        end
        
        -- Check for custom message broadcast
        local customInterval = config.getConfigValue("chat.customMessageInterval")
        if customInterval > 0 and now >= (lastCustomMessageTime + customInterval) then
            broadcastCustomMessage()
        end
    end)
end

----------------------------------------------------------------------
-- Module initialization
----------------------------------------------------------------------

-- Register event handlers
utils.safeCall("Chat registration", function()
    tm.players.OnPlayerJoined.add(onPlayerJoined)
    tm.players.OnPlayerLeft.add(onPlayerLeft)
end)

----------------------------------------------------------------------
-- Export chat functions
----------------------------------------------------------------------

return {
    update = update,
    sendCustomChatMessage = sendCustomChatMessage,
    onPlayerJoined = onPlayerJoined,
    onPlayerLeft = onPlayerLeft
}
