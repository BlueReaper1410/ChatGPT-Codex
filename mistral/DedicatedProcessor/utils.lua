-- DedicatedProcessor - Shared Utilities
-- Common error handling and helper functions for Trailmakers

local CHAT_NAME = "DedicatedProcessor"

----------------------------------------------------------------------
-- Color definitions for Trailmakers
----------------------------------------------------------------------

local CHAT_COLOR = { r = 0.75, g = 0.75, b = 0.75 }
local ERROR_COLOR = { r = 1.0, g = 0.25, b = 0.25 }
local SUCCESS_COLOR = { r = 0.25, g = 1.0, b = 0.25 }

----------------------------------------------------------------------
-- Error handling helpers
----------------------------------------------------------------------

-- Safe call wrapper that catches errors and logs them
function safeCall(where, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        local msg = "[" .. tostring(where) .. "] ERROR: " .. tostring(err)
        tm.os.Log(msg)
        SendChatMessage(CHAT_NAME, msg, ERROR_COLOR)
    end
    return ok
end

----------------------------------------------------------------------
-- Table utilities
----------------------------------------------------------------------

-- Deep copy a table
function deepCopy(original)
    if type(original) ~= "table" then
        return original
    end
    local copy = {}
    for k, v in pairs(original) do
        copy[k] = deepCopy(v)
    end
    return copy
end

-- Merge two tables (values from table2 override table1)
function mergeTables(table1, table2)
    local result = deepCopy(table1)
    for k, v in pairs(table2) do
        if type(v) == "table" and type(result[k]) == "table" then
            result[k] = mergeTables(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

----------------------------------------------------------------------
-- Player utilities
----------------------------------------------------------------------

-- Get player name safely
function GetPlayerName(playerId)
    local name = tm.players.GetPlayerName(playerId)
    if name == nil or name == "" then
        return "Player " .. tostring(playerId)
    end
    return name
end

-- Check if player is valid
function IsValidPlayer(player)
    if player == nil then return false end
    if player.playerId == nil then return false end
    return true
end

----------------------------------------------------------------------
-- Message utilities
----------------------------------------------------------------------

-- Send a chat message
function SendChatMessage(sender, message, color)
    color = color or CHAT_COLOR
    pcall(function()
        tm.playerUI.SendChatMessage(sender, message, color)
    end)
end

-- Send a subtle message
function SendSubtleMessage(message, duration, sprite, sender)
    sender = sender or CHAT_NAME
    duration = duration or 5
    sprite = sprite or ""
    pcall(function()
        tm.playerUI.AddSubtleMessageForAllPlayers(sender, message, duration, sprite)
    end)
end

-- Send error message
function SendErrorMessage(message, where)
    local fullMsg = "[" .. tostring(where) .. "] ERROR: " .. tostring(message)
    tm.os.Log(fullMsg)
    SendChatMessage(CHAT_NAME, fullMsg, ERROR_COLOR)
end

-- Send success message
function SendSuccessMessage(message, where)
    local fullMsg = "[" .. tostring(where) .. "] " .. tostring(message)
    SendChatMessage(CHAT_NAME, fullMsg, SUCCESS_COLOR)
end

----------------------------------------------------------------------
-- Export utilities
----------------------------------------------------------------------

return {
    safeCall = safeCall,
    CHAT_NAME = CHAT_NAME,
    CHAT_COLOR = CHAT_COLOR,
    ERROR_COLOR = ERROR_COLOR,
    SUCCESS_COLOR = SUCCESS_COLOR,
    deepCopy = deepCopy,
    mergeTables = mergeTables,
    GetPlayerName = GetPlayerName,
    IsValidPlayer = IsValidPlayer,
    SendChatMessage = SendChatMessage,
    SendSubtleMessage = SendSubtleMessage,
    SendErrorMessage = SendErrorMessage,
    SendSuccessMessage = SendSuccessMessage
}
