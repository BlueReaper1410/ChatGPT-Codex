-- DedicatedProcessor - DedicatedCleanup Module
-- Renamed from Cholesterol, handles structure cleanup

local utils = require("utils")
local config = require("config")

----------------------------------------------------------------------
-- State
----------------------------------------------------------------------

local cleanUpTime = 0
local structuresRemovedCount = 0

----------------------------------------------------------------------
-- Cleanup functionality
----------------------------------------------------------------------

-- Check if a structure should be removed (no seat and no camera)
local function shouldRemoveStructure(struct)
    if not struct or not struct.GetBlocks then
        return false
    end
    
    local hasSeat = false
    local hasCamera = false
    
    local blocks = struct.GetBlocks()
    if not blocks then
        return false
    end
    
    for _, structBlock in pairs(blocks) do
        if structBlock.GetName and string.match(structBlock.GetName(), "PFB_CameraDroneBlock", 1) then
            hasCamera = true
        end
        
        if structBlock.IsPlayerSeatBlock and structBlock.IsPlayerSeatBlock() then
            hasSeat = true
        end
        
        -- Early exit if both conditions are met
        if hasSeat and hasCamera then
            return false
        end
    end
    
    return not hasSeat and not hasCamera
end

-- Perform cleanup on a single player's structures
local function cleanupPlayerStructures(playerId)
    local structures = tm.players.GetPlayerStructures(playerId)
    if not structures then
        return 0
    end
    
    local removedCount = 0
    
    for i, struct in pairs(structures) do
        if shouldRemoveStructure(struct) then
            struct.Dispose()
            removedCount = removedCount + 1
        end
    end
    
    return removedCount
end

-- Main cleanup function
function cleanup()
    utils.safeCall("DedicatedCleanup.cleanup", function()
        if not config.getConfigValue("cleanup.enabled") then
            return
        end
        
        local time = math.floor(tm.os.GetTime())
        local minInterval = config.getConfigValue("cleanup.cleanupIntervalMin") or 30
        local maxInterval = config.getConfigValue("cleanup.cleanupIntervalMax") or 90
        
        -- Check if it's time to cleanup
        if time > cleanUpTime then
            local players = tm.players.CurrentPlayers()
            local totalRemoved = 0
            
            for _, p in pairs(players) do
                if p and p.playerId and not tm.players.GetPlayerIsInBuildMode(p.playerId) then
                    local removed = cleanupPlayerStructures(p.playerId)
                    totalRemoved = totalRemoved + removed
                end
            end
            
            -- Update cleanup time with random interval
            cleanUpTime = time + (math.random() * (maxInterval - minInterval) + minInterval)
            structuresRemovedCount = structuresRemovedCount + totalRemoved
            
            -- Update config with new values
            config.setConfigValue("cleanup.lastCleanupTime", cleanUpTime)
            config.setConfigValue("cleanup.structuresRemoved", structuresRemovedCount)
            
            -- Send subtle message if enabled
            if config.getConfigValue("cleanup.subtleMessagesEnabled") then
                local message = "DedicatedCleanup: Removed " .. totalRemoved .. " bad structures."
                utils.sendSubtleMessage(message, 5, "<sprite index=128>", "DedicatedCleanup")
            end
        end
    end)
end

----------------------------------------------------------------------
-- Toggle functions for UI
----------------------------------------------------------------------

-- Enable cleanup
function enableCleanup()
    config.setConfigValue("cleanup.enabled", true)
    utils.sendSuccessMessage("DedicatedCleanup enabled", "Cleanup")
end

-- Disable cleanup
function disableCleanup()
    config.setConfigValue("cleanup.enabled", false)
    utils.sendSuccessMessage("DedicatedCleanup disabled", "Cleanup")
end

-- Toggle cleanup
function toggleCleanup()
    local enabled = config.toggleConfigValue("cleanup.enabled")
    if enabled then
        utils.sendSuccessMessage("DedicatedCleanup enabled", "Cleanup")
    else
        utils.sendSuccessMessage("DedicatedCleanup disabled", "Cleanup")
    end
    return enabled
end

-- Toggle subtle messages
function toggleSubtleMessages()
    local enabled = config.toggleConfigValue("cleanup.subtleMessagesEnabled")
    if enabled then
        utils.sendSuccessMessage("Cleanup subtle messages enabled", "Cleanup")
    else
        utils.sendSuccessMessage("Cleanup subtle messages disabled", "Cleanup")
    end
    return enabled
end

-- Get cleanup status
function getCleanupStatus()
    return {
        enabled = config.getConfigValue("cleanup.enabled"),
        subtleMessagesEnabled = config.getConfigValue("cleanup.subtleMessagesEnabled"),
        structuresRemoved = config.getConfigValue("cleanup.structuresRemoved") or 0,
        nextCleanupTime = cleanUpTime
    }
end

----------------------------------------------------------------------
-- Update function
----------------------------------------------------------------------

function update()
    cleanup()
end

----------------------------------------------------------------------
-- Module initialization
----------------------------------------------------------------------

-- Send initial loaded message
utils.safeCall("DedicatedCleanup init", function()
    if config.getConfigValue("cleanup.subtleMessagesEnabled") then
        utils.sendSubtleMessage("DedicatedCleanup V1.0 loaded...", 5, "<sprite index=128>", "DedicatedCleanup")
    end
end)

----------------------------------------------------------------------
-- Export cleanup functions
----------------------------------------------------------------------

return {
    update = update,
    cleanup = cleanup,
    enableCleanup = enableCleanup,
    disableCleanup = disableCleanup,
    toggleCleanup = toggleCleanup,
    toggleSubtleMessages = toggleSubtleMessages,
    getCleanupStatus = getCleanupStatus
}
