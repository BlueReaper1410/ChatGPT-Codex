-- DedicatedProcessor - Main Module
-- Core mod lifecycle and coordination for Trailmakers

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
-- Chat command handler
----------------------------------------------------------------------

function OnChatCommand(command, args)
    utils.safeCall("OnChatCommand", function()
        if command == "dp" or command == "dedicatedprocessor" then
            ui.ToggleUI()
        elseif command == "dphelp" or command == "dedicatedprocessorhelp" then
            ShowHelp()
        end
    end)
end

----------------------------------------------------------------------
-- Help function
----------------------------------------------------------------------

function ShowHelp()
    utils.safeCall("ShowHelp", function()
        utils.SendChatMessage(utils.CHAT_NAME, "DedicatedProcessor Commands:", utils.SUCCESS_COLOR)
        utils.SendChatMessage(utils.CHAT_NAME, "  /dp - Toggle the DedicatedProcessor UI", utils.CHAT_COLOR)
        utils.SendChatMessage(utils.CHAT_NAME, "  /dphelp - Show this help message", utils.CHAT_COLOR)
    end)
end

----------------------------------------------------------------------
-- Main update function
----------------------------------------------------------------------

function Update()
    utils.safeCall("Main.Update", function()
        if not config.GetConfigValue("modEnabled") then
            return
        end
        
        chat.Update()
        cleanup.Update()
        ui.UpdateUI()
        ui.DrawUI()
        ui.HandleInput()
    end)
end

----------------------------------------------------------------------
-- Module initialization
----------------------------------------------------------------------

utils.safeCall("OnModLoaded", function()
    tm.os.Log(MOD_NAME .. " " .. MOD_VERSION .. " loaded!")
    
    config.LoadConfig()
    
    if not config.GetConfigValue("modEnabled") then
        tm.os.Log(MOD_NAME .. " is disabled by configuration")
        return
    end
    
    tm.os.AddUpdateCallback(Update)
    
    if config.GetConfigValue("cleanup.subtleMessagesEnabled") then
        utils.SendSubtleMessage(MOD_NAME .. " " .. MOD_VERSION .. " loaded...", 5, "")
    end
    
    utils.SendSuccessMessage("Mod loaded successfully", "Main")
end)

-- Register chat command
utils.safeCall("Chat command registration", function()
    tm.playerUI.AddChatCommandHandler(OnChatCommand)
end)
