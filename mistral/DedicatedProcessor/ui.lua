-- DedicatedProcessor - UI Module
-- Server host UI for managing mod features in Trailmakers

local utils = require("utils")
local config = require("config")
local chat = require("chat")
local cleanup = require("cleanup")

----------------------------------------------------------------------
-- UI State
----------------------------------------------------------------------

local UI = {
    isOpen = false,
    currentPage = "main",
    inputBuffer = "",
    cursorPosition = 0,
    blinkTimer = 0,
    showCursor = true
}

----------------------------------------------------------------------
-- UI Configuration
----------------------------------------------------------------------

local UI_CONFIG = {
    backgroundColor = { r = 0.1, g = 0.1, b = 0.1, a = 0.9 },
    textColor = { r = 0.9, g = 0.9, b = 0.9 },
    buttonColor = { r = 0.2, g = 0.2, b = 0.2 },
    buttonHoverColor = { r = 0.3, g = 0.3, b = 0.3 },
    buttonActiveColor = { r = 0.4, g = 0.4, b = 0.4 },
    toggleOnColor = { r = 0, g = 0.8, b = 0 },
    toggleOffColor = { r = 0.8, g = 0, b = 0 },
    inputColor = { r = 0.15, g = 0.15, b = 0.15 },
    inputTextColor = { r = 1, g = 1, b = 1 },
    borderColor = { r = 0.5, g = 0.5, b = 0.5 },
    
    padding = 10,
    buttonHeight = 30,
    buttonSpacing = 5,
    inputHeight = 25,
    lineHeight = 20,
    
    windowWidth = 400,
    windowHeight = 500
}

----------------------------------------------------------------------
-- UI Helper Functions
----------------------------------------------------------------------

local function DrawRect(x, y, width, height, color)
    pcall(function()
        tm.playerUI.DrawRect(x, y, width, height, color.r, color.g, color.b, color.a or 1.0)
    end)
end

local function DrawText(text, x, y, color, scale)
    scale = scale or 1.0
    pcall(function()
        tm.playerUI.DrawText(text, x, y, color.r, color.g, color.b, color.a or 1.0, scale)
    end)
end

local function DrawButton(x, y, width, height, text, isHovered, isActive)
    local color = UI_CONFIG.buttonColor
    if isActive then
        color = UI_CONFIG.buttonActiveColor
    elseif isHovered then
        color = UI_CONFIG.buttonHoverColor
    end
    
    DrawRect(x, y, width, height, color)
    
    -- Border
    DrawRect(x, y, width, 1, UI_CONFIG.borderColor)
    DrawRect(x, y + height - 1, width, 1, UI_CONFIG.borderColor)
    DrawRect(x, y, 1, height, UI_CONFIG.borderColor)
    DrawRect(x + width - 1, y, 1, height, UI_CONFIG.borderColor)
    
    -- Text
    local textWidth = tm.playerUI.GetTextWidth(text) * 0.8
    local textX = x + (width - textWidth) / 2
    local textY = y + (height - UI_CONFIG.lineHeight) / 2
    DrawText(text, textX, textY, UI_CONFIG.textColor, 0.8)
end

local function DrawToggle(x, y, width, height, isOn, label)
    local toggleWidth = height * 1.5
    local toggleX = x + width - toggleWidth - 5
    
    DrawText(label, x, y + (height - UI_CONFIG.lineHeight) / 2, UI_CONFIG.textColor, 0.8)
    
    local bgColor = isOn and UI_CONFIG.toggleOnColor or UI_CONFIG.toggleOffColor
    DrawRect(toggleX, y, toggleWidth, height, bgColor)
    
    DrawRect(toggleX, y, toggleWidth, 1, UI_CONFIG.borderColor)
    DrawRect(toggleX, y + height - 1, toggleWidth, 1, UI_CONFIG.borderColor)
    DrawRect(toggleX, y, 1, height, UI_CONFIG.borderColor)
    DrawRect(toggleX + toggleWidth - 1, y, 1, height, UI_CONFIG.borderColor)
    
    local circleSize = height - 4
    local circleX = isOn and (toggleX + toggleWidth - circleSize - 2) or (toggleX + 2)
    local circleY = y + 2
    
    pcall(function()
        tm.playerUI.DrawCircle(circleX + circleSize/2, circleY + circleSize/2, circleSize/2, 
                              1, 1, 1, 1, true)
    end)
end

local function DrawInputField(x, y, width, height, text, isActive)
    local color = isActive and UI_CONFIG.inputColor or 
                  { r = UI_CONFIG.inputColor.r * 0.7, g = UI_CONFIG.inputColor.g * 0.7, 
                    b = UI_CONFIG.inputColor.b * 0.7 }
    
    DrawRect(x, y, width, height, color)
    
    local borderColor = isActive and UI_CONFIG.borderColor or 
                        { r = UI_CONFIG.borderColor.r * 0.5, g = UI_CONFIG.borderColor.g * 0.5, 
                          b = UI_CONFIG.borderColor.b * 0.5 }
    DrawRect(x, y, width, 1, borderColor)
    DrawRect(x, y + height - 1, width, 1, borderColor)
    DrawRect(x, y, 1, height, borderColor)
    DrawRect(x + width - 1, y, 1, height, borderColor)
    
    local displayText = text
    if isActive and UI.showCursor then
        local beforeCursor = string.sub(text, 1, UI.cursorPosition)
        local afterCursor = string.sub(text, UI.cursorPosition + 1)
        displayText = beforeCursor .. "|" .. afterCursor
    end
    
    DrawText(displayText, x + 5, y + (height - UI_CONFIG.lineHeight) / 2, UI_CONFIG.inputTextColor, 0.8)
end

local function IsInRect(x, y, rectX, rectY, rectWidth, rectHeight)
    return x >= rectX and x <= rectX + rectWidth and 
           y >= rectY and y <= rectY + rectHeight
end

----------------------------------------------------------------------
-- UI Pages
----------------------------------------------------------------------

local function DrawMainPage(x, y, width, height)
    local currentY = y + UI_CONFIG.padding
    
    DrawText("DedicatedProcessor", x + width/2 - tm.playerUI.GetTextWidth("DedicatedProcessor")/2, 
             currentY, UI_CONFIG.textColor, 1.2)
    currentY = currentY + UI_CONFIG.lineHeight * 1.5
    
    local modEnabled = config.GetConfigValue("modEnabled")
    local statusText = modEnabled and "Status: ENABLED" or "Status: DISABLED"
    local statusColor = modEnabled and UI_CONFIG.toggleOnColor or UI_CONFIG.toggleOffColor
    DrawText(statusText, x + UI_CONFIG.padding, currentY, statusColor, 0.8)
    currentY = currentY + UI_CONFIG.lineHeight * 1.5
    
    local buttonWidth = width - UI_CONFIG.padding * 2
    
    DrawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Chat Settings", false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    DrawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "DedicatedCleanup Settings", false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    DrawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "General Utilities", false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    local buttonText = modEnabled and "Disable Mod" or "Enable Mod"
    DrawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               buttonText, false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    DrawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Close", false, false)
end

local function DrawChatSettingsPage(x, y, width, height)
    local currentY = y + UI_CONFIG.padding
    
    DrawText("Chat Settings", x + width/2 - tm.playerUI.GetTextWidth("Chat Settings")/2, 
             currentY, UI_CONFIG.textColor, 1.2)
    currentY = currentY + UI_CONFIG.lineHeight * 1.5
    
    local greetEnabled = config.GetConfigValue("chat.greetNewPlayers")
    DrawToggle(x + UI_CONFIG.padding, currentY, width - UI_CONFIG.padding * 2, 
               UI_CONFIG.buttonHeight, greetEnabled, "Greet new players")
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    local customEnabled = config.GetConfigValue("chat.customMessageEnabled")
    DrawToggle(x + UI_CONFIG.padding, currentY, width - UI_CONFIG.padding * 2, 
               UI_CONFIG.buttonHeight, customEnabled, "Enable custom message")
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    DrawText("Custom message:", x + UI_CONFIG.padding, currentY, UI_CONFIG.textColor, 0.8)
    currentY = currentY + UI_CONFIG.lineHeight
    
    local inputWidth = width - UI_CONFIG.padding * 2
    DrawInputField(x + UI_CONFIG.padding, currentY, inputWidth, UI_CONFIG.inputHeight, 
                   config.GetConfigValue("chat.customMessage") or "", 
                   UI.currentPage == "chat_input")
    currentY = currentY + UI_CONFIG.inputHeight + UI_CONFIG.buttonSpacing
    
    local buttonWidth = width - UI_CONFIG.padding * 2
    DrawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Send Custom Message", false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    DrawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Back", false, false)
end

local function DrawCleanupSettingsPage(x, y, width, height)
    local currentY = y + UI_CONFIG.padding
    
    DrawText("DedicatedCleanup Settings", x + width/2 - tm.playerUI.GetTextWidth("DedicatedCleanup Settings")/2, 
             currentY, UI_CONFIG.textColor, 1.2)
    currentY = currentY + UI_CONFIG.lineHeight * 1.5
    
    local cleanupEnabled = config.GetConfigValue("cleanup.enabled")
    DrawToggle(x + UI_CONFIG.padding, currentY, width - UI_CONFIG.padding * 2, 
               UI_CONFIG.buttonHeight, cleanupEnabled, "Enable DedicatedCleanup")
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    local subtleEnabled = config.GetConfigValue("cleanup.subtleMessagesEnabled")
    DrawToggle(x + UI_CONFIG.padding, currentY, width - UI_CONFIG.padding * 2, 
               UI_CONFIG.buttonHeight, subtleEnabled, "Show subtle messages")
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    DrawText("Cleanup interval (seconds):", x + UI_CONFIG.padding, currentY, UI_CONFIG.textColor, 0.8)
    currentY = currentY + UI_CONFIG.lineHeight
    
    local minInterval = config.GetConfigValue("cleanup.cleanupIntervalMin") or 30
    local maxInterval = config.GetConfigValue("cleanup.cleanupIntervalMax") or 90
    DrawText(string.format("Min: %d, Max: %d", minInterval, maxInterval), 
             x + UI_CONFIG.padding, currentY, UI_CONFIG.textColor, 0.8)
    currentY = currentY + UI_CONFIG.lineHeight
    
    local removedCount = config.GetConfigValue("cleanup.structuresRemoved") or 0
    DrawText(string.format("Structures removed: %d", removedCount), 
             x + UI_CONFIG.padding, currentY, UI_CONFIG.textColor, 0.8)
    currentY = currentY + UI_CONFIG.lineHeight * 1.5
    
    local buttonWidth = width - UI_CONFIG.padding * 2
    DrawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Force Cleanup Now", false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    DrawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Back", false, false)
end

local function DrawGeneralUtilitiesPage(x, y, width, height)
    local currentY = y + UI_CONFIG.padding
    
    DrawText("General Utilities", x + width/2 - tm.playerUI.GetTextWidth("General Utilities")/2, 
             currentY, UI_CONFIG.textColor, 1.2)
    currentY = currentY + UI_CONFIG.lineHeight * 1.5
    
    local modEnabled = config.GetConfigValue("modEnabled")
    DrawToggle(x + UI_CONFIG.padding, currentY, width - UI_CONFIG.padding * 2, 
               UI_CONFIG.buttonHeight, modEnabled, "Mod Enabled")
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    local statusEnabled = config.GetConfigValue("ui.showStatusMessages")
    DrawToggle(x + UI_CONFIG.padding, currentY, width - UI_CONFIG.padding * 2, 
               UI_CONFIG.buttonHeight, statusEnabled, "Show status messages")
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    local buttonWidth = width - UI_CONFIG.padding * 2
    DrawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Reset to Defaults", false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    DrawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Back", false, false)
end

----------------------------------------------------------------------
-- UI Drawing
----------------------------------------------------------------------

function DrawUI()
    if not UI.isOpen then
        return
    end
    
    local screenWidth, screenHeight = tm.playerUI.GetScreenSize()
    local windowX = (screenWidth - UI_CONFIG.windowWidth) / 2
    local windowY = (screenHeight - UI_CONFIG.windowHeight) / 2
    
    DrawRect(windowX, windowY, UI_CONFIG.windowWidth, UI_CONFIG.windowHeight, UI_CONFIG.backgroundColor)
    
    DrawRect(windowX, windowY, UI_CONFIG.windowWidth, 1, UI_CONFIG.borderColor)
    DrawRect(windowX, windowY + UI_CONFIG.windowHeight - 1, UI_CONFIG.windowWidth, 1, UI_CONFIG.borderColor)
    DrawRect(windowX, windowY, 1, UI_CONFIG.windowHeight, UI_CONFIG.borderColor)
    DrawRect(windowX + UI_CONFIG.windowWidth - 1, windowY, 1, UI_CONFIG.windowHeight, UI_CONFIG.borderColor)
    
    if UI.currentPage == "main" then
        DrawMainPage(windowX, windowY, UI_CONFIG.windowWidth, UI_CONFIG.windowHeight)
    elseif UI.currentPage == "chat" then
        DrawChatSettingsPage(windowX, windowY, UI_CONFIG.windowWidth, UI_CONFIG.windowHeight)
    elseif UI.currentPage == "cleanup" then
        DrawCleanupSettingsPage(windowX, windowY, UI_CONFIG.windowWidth, UI_CONFIG.windowHeight)
    elseif UI.currentPage == "general" then
        DrawGeneralUtilitiesPage(windowX, windowY, UI_CONFIG.windowWidth, UI_CONFIG.windowHeight)
    end
end

----------------------------------------------------------------------
-- UI Input Handling
----------------------------------------------------------------------

function HandleInput()
    if not UI.isOpen then
        return
    end
    
    local mouseX, mouseY = tm.playerUI.GetMousePosition()
    local mouseDown = tm.playerUI.IsMouseButtonDown(0)
    local keyPressed = tm.playerUI.GetLastKeyPressed()
    
    local screenWidth, screenHeight = tm.playerUI.GetScreenSize()
    local windowX = (screenWidth - UI_CONFIG.windowWidth) / 2
    local windowY = (screenHeight - UI_CONFIG.windowHeight) / 2
    
    local inWindow = IsInRect(mouseX, mouseY, windowX, windowY, UI_CONFIG.windowWidth, UI_CONFIG.windowHeight)
    
    if inWindow and mouseDown then
        local relativeX = mouseX - windowX
        local relativeY = mouseY - windowY
        
        if UI.currentPage == "main" then
            local currentY = UI_CONFIG.padding + UI_CONFIG.lineHeight * 1.5 + UI_CONFIG.lineHeight * 1.5
            local buttonWidth = UI_CONFIG.windowWidth - UI_CONFIG.padding * 2
            local buttonHeight = UI_CONFIG.buttonHeight
            local buttonSpacing = UI_CONFIG.buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.currentPage = "chat"
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.currentPage = "cleanup"
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.currentPage = "general"
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                local enabled = config.ToggleConfigValue("modEnabled")
                if enabled then
                    utils.SendSuccessMessage("DedicatedProcessor enabled", "UI")
                else
                    utils.SendSuccessMessage("DedicatedProcessor disabled", "UI")
                end
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.isOpen = false
                return
            end
            
        elseif UI.currentPage == "chat" then
            local currentY = UI_CONFIG.padding + UI_CONFIG.lineHeight * 1.5
            local buttonWidth = UI_CONFIG.windowWidth - UI_CONFIG.padding * 2
            local buttonHeight = UI_CONFIG.buttonHeight
            local buttonSpacing = UI_CONFIG.buttonSpacing
            local inputHeight = UI_CONFIG.inputHeight
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                config.ToggleConfigValue("chat.greetNewPlayers")
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                config.ToggleConfigValue("chat.customMessageEnabled")
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            currentY = currentY + UI_CONFIG.lineHeight
            
            local inputY = currentY
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, inputY, buttonWidth, inputHeight) then
                UI.currentPage = "chat_input"
                return
            end
            currentY = currentY + inputHeight + buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                local message = config.GetConfigValue("chat.customMessage") or ""
                chat.SendCustomChatMessage(message)
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.currentPage = "main"
                return
            end
            
        elseif UI.currentPage == "cleanup" then
            local currentY = UI_CONFIG.padding + UI_CONFIG.lineHeight * 1.5
            local buttonWidth = UI_CONFIG.windowWidth - UI_CONFIG.padding * 2
            local buttonHeight = UI_CONFIG.buttonHeight
            local buttonSpacing = UI_CONFIG.buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                cleanup.ToggleCleanup()
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                cleanup.ToggleSubtleMessages()
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            currentY = currentY + UI_CONFIG.lineHeight * 2
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                cleanup.Cleanup()
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.currentPage = "main"
                return
            end
            
        elseif UI.currentPage == "general" then
            local currentY = UI_CONFIG.padding + UI_CONFIG.lineHeight * 1.5
            local buttonWidth = UI_CONFIG.windowWidth - UI_CONFIG.padding * 2
            local buttonHeight = UI_CONFIG.buttonHeight
            local buttonSpacing = UI_CONFIG.buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                local enabled = config.ToggleConfigValue("modEnabled")
                if enabled then
                    utils.SendSuccessMessage("DedicatedProcessor enabled", "UI")
                else
                    utils.SendSuccessMessage("DedicatedProcessor disabled", "UI")
                end
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                config.ToggleConfigValue("ui.showStatusMessages")
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                config.SetConfigValue("modEnabled", true)
                config.SetConfigValue("chat.greetNewPlayers", true)
                config.SetConfigValue("chat.customMessageEnabled", false)
                config.SetConfigValue("chat.customMessage", "Welcome to the server!")
                config.SetConfigValue("cleanup.enabled", true)
                config.SetConfigValue("cleanup.subtleMessagesEnabled", true)
                config.SetConfigValue("ui.showStatusMessages", true)
                utils.SendSuccessMessage("Configuration reset to defaults", "UI")
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            if IsInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.currentPage = "main"
                return
            end
        end
    end
    
    -- Handle keyboard input for input fields
    if UI.currentPage == "chat_input" then
        if keyPressed then
            if keyPressed == 8 then -- Backspace
                if UI.cursorPosition > 0 then
                    local currentText = config.GetConfigValue("chat.customMessage") or ""
                    local newText = string.sub(currentText, 1, UI.cursorPosition - 1) .. 
                                   string.sub(currentText, UI.cursorPosition + 1)
                    config.SetConfigValue("chat.customMessage", newText)
                    UI.cursorPosition = UI.cursorPosition - 1
                end
                
            elseif keyPressed == 13 then -- Enter
                UI.currentPage = "chat"
                
            elseif keyPressed == 27 then -- Escape
                UI.currentPage = "chat"
                
            elseif keyPressed >= 32 and keyPressed <= 126 then
                local char = string.char(keyPressed)
                local currentText = config.GetConfigValue("chat.customMessage") or ""
                local newText = string.sub(currentText, 1, UI.cursorPosition) .. char .. 
                               string.sub(currentText, UI.cursorPosition + 1)
                config.SetConfigValue("chat.customMessage", newText)
                UI.cursorPosition = UI.cursorPosition + 1
            end
        end
    end
end

----------------------------------------------------------------------
-- UI Update
----------------------------------------------------------------------

function UpdateUI()
    if not UI.isOpen then
        return
    end
    
    UI.blinkTimer = UI.blinkTimer + 0.1
    if UI.blinkTimer >= 1.0 then
        UI.showCursor = not UI.showCursor
        UI.blinkTimer = 0
    end
end

----------------------------------------------------------------------
-- UI Toggle
----------------------------------------------------------------------

function ToggleUI()
    UI.isOpen = not UI.isOpen
    if UI.isOpen then
        UI.currentPage = "main"
        UI.inputBuffer = ""
        UI.cursorPosition = 0
    end
end

function OpenUI()
    UI.isOpen = true
    UI.currentPage = "main"
end

function CloseUI()
    UI.isOpen = false
end

----------------------------------------------------------------------
-- Export UI functions
----------------------------------------------------------------------

return {
    DrawUI = DrawUI,
    HandleInput = HandleInput,
    UpdateUI = UpdateUI,
    ToggleUI = ToggleUI,
    OpenUI = OpenUI,
    CloseUI = CloseUI
}
