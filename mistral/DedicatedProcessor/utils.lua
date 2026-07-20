-- DedicatedProcessor - Shared Utilities
-- Common error handling and helper functions

local CHAT_NAME = "DedicatedProcessor"

----------------------------------------------------------------------
-- Error handling helpers
----------------------------------------------------------------------

-- Runs fn() protected. On failure: logs the error and (best-effort) echoes
-- it to chat. Never throws itself, no matter what goes wrong inside fn.
local function safeCall(where, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        local msg = "[" .. tostring(where) .. "] ERROR: " .. tostring(err)
        pcall(function() tm.os.Log(msg) end)
        pcall(function() tm.playerUI.SendChatMessage(CHAT_NAME, msg) end)
    end
    return ok
end

-- Try a few plausible ways of getting a grey ModColor
local function tryColor(fn)
    local ok, result = pcall(fn)
    if ok then return result end
    return nil
end

-- Get a grey color for chat messages, with fallbacks
local CHAT_COLOR = tryColor(function() return tm.color.Grey() end)
    or tryColor(function() return tm.color.Gray() end)
    or tryColor(function() return tm.color.RGB(0.5, 0.5, 0.5) end)
    or tryColor(function() return tm.color.Create(0.5, 0.5, 0.5) end)

-- Get a red color for error messages
local ERROR_COLOR = tryColor(function() return tm.color.Red() end)
    or tryColor(function() return tm.color.RGB(1, 0, 0) end)
    or tryColor(function() return tm.color.Create(1, 0, 0) end)

-- Get a green color for success messages
local SUCCESS_COLOR = tryColor(function() return tm.color.Green() end)
    or tryColor(function() return tm.color.RGB(0, 1, 0) end)
    or tryColor(function() return tm.color.Create(0, 1, 0) end)

----------------------------------------------------------------------
-- Table utilities
----------------------------------------------------------------------

-- Deep copy a table
function deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
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
function getPlayerName(playerId)
    local name = tm.players.GetPlayerName(playerId)
    if name == nil or name == "" then
        return "Player " .. tostring(playerId)
    end
    return name
end

-- Check if player is valid
function isValidPlayer(player)
    if player == nil then return false end
    if player.playerId == nil then return false end
    return true
end

----------------------------------------------------------------------
-- Message utilities
----------------------------------------------------------------------

-- Send a chat message with optional color
function sendChatMessage(message, color, sender)
    sender = sender or CHAT_NAME
    color = color or CHAT_COLOR
    pcall(function()
        tm.playerUI.SendChatMessage(sender, message, color)
    end)
end

-- Send a subtle message with optional sprite
function sendSubtleMessage(message, duration, sprite, sender)
    sender = sender or CHAT_NAME
    duration = duration or 5
    sprite = sprite or ""
    pcall(function()
        tm.playerUI.AddSubtleMessageForAllPlayers(sender, message, duration, sprite)
    end)
end

-- Send error message
function sendErrorMessage(message, where)
    local fullMsg = "[" .. tostring(where) .. "] ERROR: " .. tostring(message)
    pcall(function() tm.os.Log(fullMsg) end)
    sendChatMessage(fullMsg, ERROR_COLOR)
end

-- Send success message
function sendSuccessMessage(message, where)
    local fullMsg = "[" .. tostring(where) .. "] " .. tostring(message)
    sendChatMessage(fullMsg, SUCCESS_COLOR)
end

----------------------------------------------------------------------
-- Export utilities
----------------------------------------------------------------------

return {
    safeCall = safeCall,
    tryColor = tryColor,
    CHAT_NAME = CHAT_NAME,
    CHAT_COLOR = CHAT_COLOR,
    ERROR_COLOR = ERROR_COLOR,
    SUCCESS_COLOR = SUCCESS_COLOR,
    deepCopy = deepCopy,
    mergeTables = mergeTables,
    getPlayerName = getPlayerName,
    isValidPlayer = isValidPlayer,
    sendChatMessage = sendChatMessage,
    sendSubtleMessage = sendSubtleMessage,
    sendErrorMessage = sendErrorMessage,
    sendSuccessMessage = sendSuccessMessage
}
