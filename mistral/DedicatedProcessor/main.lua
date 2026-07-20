-- DedicatedProcessor - Main Module
-- Core mod lifecycle and coordination

local utils = require("utils")
local config = require("config")
local chat = require("chat")
local cleanup = require("cleanup")
local ui = require("ui")

----------------------------------------------------------------------
-- Mod metadata
----------------------------------------------------------------------

local MOD_NAME = "DedicatedProcessor"
local MOD_VERSION = "1.0.0"

----------------------------------------------------------------------
-- Mod lifecycle
----------------------------------------------------------------------

function OnModLoaded()
    utils.safeCall("OnModLoaded", function()
        tm.os.Log(MOD_NAME .. " " .. MOD_VERSION .. " loaded!")
        
        -- Initialize all modules
        config.loadConfig()
        
        -- Check if mod is enabled
        if not config.getConfigValue("modEnabled") then
            tm.os.Log(MOD_NAME .. " is disabled by configuration")
            return
        end
        
        -- Register event handlers
        registerEventHandlers()
        
        -- Send loaded message
        if config.getConfigValue("cleanup.subtleMessagesEnabled") then
            utils.sendSubtleMessage(MOD_NAME .. " " .. MOD_VERSION .. " loaded...", 5, "<sprite index=128>")
        end
        
        utils.sendSuccessMessage("Mod loaded successfully", "Main")
    end)
end

----------------------------------------------------------------------
-- Event Handler Registration
----------------------------------------------------------------------

function registerEventHandlers()
    utils.safeCall("registerEventHandlers", function()
        -- Player events are already registered in chat.lua
        -- We just need to make sure our update function is called
        
        -- Register our main update function
        tm.os.AddUpdateCallback(update)
    end)
end

----------------------------------------------------------------------
-- Main update function
----------------------------------------------------------------------

function update()
    utils.safeCall("Main.update", function()
        -- Check if mod is enabled
        if not config.getConfigValue("modEnabled") then
            return
        end
        
        -- Update all modules
        chat.update()
        cleanup.update()
        ui.updateUI()
        
        -- Draw UI
        ui.drawUI()
        
        -- Handle UI input
        ui.handleInput()
    end)
end

----------------------------------------------------------------------
-- Chat command for UI toggle
----------------------------------------------------------------------

function OnChatCommand(command, args)
    utils.safeCall("OnChatCommand", function()
        if command == "dp" or command == "dedicatedprocessor" then
            ui.toggleUI()
        elseif command == "dphelp" or command == "dedicatedprocessorhelp" then
            showHelp()
        end
    end)
end

----------------------------------------------------------------------
-- Help function
----------------------------------------------------------------------

function showHelp()
    utils.safeCall("showHelp", function()
        utils.sendChatMessage("DedicatedProcessor Commands:", utils.SUCCESS_COLOR)
        utils.sendChatMessage("  /dp - Toggle the DedicatedProcessor UI", utils.CHAT_COLOR)
        utils.sendChatMessage("  /dphelp - Show this help message", utils.CHAT_COLOR)
    end)
end

----------------------------------------------------------------------
-- Module initialization
----------------------------------------------------------------------

-- Call OnModLoaded when the mod is loaded
utils.safeCall("OnModLoaded (top level call)", OnModLoaded)

-- Register chat command
utils.safeCall("Chat command registration", function()
    tm.playerUI.AddChatCommandHandler(OnChatCommand)
end)

----------------------------------------------------------------------
-- Export main functions (if needed)
----------------------------------------------------------------------

return {
    OnModLoaded = OnModLoaded,
    update = update,
    registerEventHandlers = registerEventHandlers,
    showHelp = showHelp
}
