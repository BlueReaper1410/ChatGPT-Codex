-- DedicatedProcessor - DedicatedCleanup Module
-- Renamed from Cholesterol, handles structure cleanup for Trailmakers

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

local function ShouldRemoveStructure(struct)
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
        if structBlock.GetName then
            local name = structBlock.GetName()
            if name and string.find(name, "CameraDroneBlock", 1, true) then
                hasCamera = true
            end
        end
        
        if structBlock.IsPlayerSeatBlock and structBlock.IsPlayerSeatBlock() then
            hasSeat = true
        end
        
        if hasSeat and hasCamera then
            return false
        end
    end
    
    return not hasSeat and not hasCamera
end

local function CleanupPlayerStructures(playerId)
    local structures = tm.players.GetPlayerStructures(playerId)
    if not structures then
        return 0
    end
    
    local removedCount = 0
    
    for i, struct in pairs(structures) do
        if ShouldRemoveStructure(struct) then
            pcall(function() struct.Dispose() end)
            removedCount = removedCount + 1
        end
    end
    
    return removedCount
end

function Cleanup()
    utils.safeCall("DedicatedCleanup.Cleanup", function()
        if not config.GetConfigValue("cleanup.enabled") then
            return
        end
        
        local time = math.floor(tm.os.GetTime())
        local minInterval = config.GetConfigValue("cleanup.cleanupIntervalMin") or 30
        local maxInterval = config.GetConfigValue("cleanup.cleanupIntervalMax") or 90
        
        if time > cleanUpTime then
            local players = tm.players.CurrentPlayers()
            local totalRemoved = 0
            
            for _, p in pairs(players) do
                if p and p.playerId and not tm.players.GetPlayerIsInBuildMode(p.playerId) then
                    local removed = CleanupPlayerStructures(p.playerId)
                    totalRemoved = totalRemoved + removed
                end
            end
            
            cleanUpTime = time + (math.random() * (maxInterval - minInterval) + minInterval)
            structuresRemovedCount = structuresRemovedCount + totalRemoved
            
            config.SetConfigValue("cleanup.lastCleanupTime", cleanUpTime)
            config.SetConfigValue("cleanup.structuresRemoved", structuresRemovedCount)
            
            if config.GetConfigValue("cleanup.subtleMessagesEnabled") then
                local message = "DedicatedCleanup: Removed " .. totalRemoved .. " bad structures."
                utils.SendSubtleMessage(message, 5, "", "DedicatedCleanup")
            end
        end
    end)
end

----------------------------------------------------------------------
-- Toggle functions for UI
----------------------------------------------------------------------

function EnableCleanup()
    config.SetConfigValue("cleanup.enabled", true)
    utils.SendSuccessMessage("DedicatedCleanup enabled", "Cleanup")
end

function DisableCleanup()
    config.SetConfigValue("cleanup.enabled", false)
    utils.SendSuccessMessage("DedicatedCleanup disabled", "Cleanup")
end

function ToggleCleanup()
    local enabled = config.ToggleConfigValue("cleanup.enabled")
    if enabled then
        utils.SendSuccessMessage("DedicatedCleanup enabled", "Cleanup")
    else
        utils.SendSuccessMessage("DedicatedCleanup disabled", "Cleanup")
    end
    return enabled
end

function ToggleSubtleMessages()
    local enabled = config.ToggleConfigValue("cleanup.subtleMessagesEnabled")
    if enabled then
        utils.SendSuccessMessage("Cleanup subtle messages enabled", "Cleanup")
    else
        utils.SendSuccessMessage("Cleanup subtle messages disabled", "Cleanup")
    end
    return enabled
end

function GetCleanupStatus()
    return {
        enabled = config.GetConfigValue("cleanup.enabled"),
        subtleMessagesEnabled = config.GetConfigValue("cleanup.subtleMessagesEnabled"),
        structuresRemoved = config.GetConfigValue("cleanup.structuresRemoved") or 0,
        nextCleanupTime = cleanUpTime
    }
end

----------------------------------------------------------------------
-- Update function
----------------------------------------------------------------------

function Update()
    Cleanup()
end

----------------------------------------------------------------------
-- Module initialization
----------------------------------------------------------------------

utils.safeCall("DedicatedCleanup init", function()
    if config.GetConfigValue("cleanup.subtleMessagesEnabled") then
        utils.SendSubtleMessage("DedicatedCleanup V1.0 loaded...", 5, "", "DedicatedCleanup")
    end
end)

----------------------------------------------------------------------
-- Export cleanup functions
----------------------------------------------------------------------

return {
    Update = Update,
    Cleanup = Cleanup,
    EnableCleanup = EnableCleanup,
    DisableCleanup = DisableCleanup,
    ToggleCleanup = ToggleCleanup,
    ToggleSubtleMessages = ToggleSubtleMessages,
    GetCleanupStatus = GetCleanupStatus
}
