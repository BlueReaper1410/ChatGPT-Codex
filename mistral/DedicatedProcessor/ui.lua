-- DedicatedProcessor - UI Module
-- Server host UI for managing mod features

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
    backgroundColor = {r = 0.1, g = 0.1, b = 0.1, a = 0.9},
    textColor = {r = 0.9, g = 0.9, b = 0.9, a = 1.0},
    buttonColor = {r = 0.2, g = 0.2, b = 0.2, a = 0.8},
    buttonHoverColor = {r = 0.3, g = 0.3, b = 0.3, a = 0.9},
    buttonActiveColor = {r = 0.4, g = 0.4, b = 0.4, a = 1.0},
    toggleOnColor = {r = 0, g = 0.8, b = 0, a = 1.0},
    toggleOffColor = {r = 0.8, g = 0, b = 0, a = 1.0},
    inputColor = {r = 0.15, g = 0.15, b = 0.15, a = 0.9},
    inputTextColor = {r = 1, g = 1, b = 1, a = 1.0},
    borderColor = {r = 0.5, g = 0.5, b = 0.5, a = 0.5},
    
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

-- Draw a rectangle
local function drawRect(x, y, width, height, color)
    pcall(function()
        tm.playerUI.DrawRect(x, y, width, height, color.r, color.g, color.b, color.a)
    end)
end

-- Draw text
local function drawText(text, x, y, color, scale)
    scale = scale or 1.0
    pcall(function()
        tm.playerUI.DrawText(text, x, y, color.r, color.g, color.b, color.a, scale)
    end)
end

-- Draw a button
local function drawButton(x, y, width, height, text, isHovered, isActive)
    local color = UI_CONFIG.buttonColor
    if isActive then
        color = UI_CONFIG.buttonActiveColor
    elseif isHovered then
        color = UI_CONFIG.buttonHoverColor
    end
    
    -- Draw button background
    drawRect(x, y, width, height, color)
    
    -- Draw button border
    drawRect(x, y, width, 1, UI_CONFIG.borderColor) -- top
    drawRect(x, y + height - 1, width, 1, UI_CONFIG.borderColor) -- bottom
    drawRect(x, y, 1, height, UI_CONFIG.borderColor) -- left
    drawRect(x + width - 1, y, 1, height, UI_CONFIG.borderColor) -- right
    
    -- Draw button text
    local textWidth = tm.playerUI.GetTextWidth(text) * 0.8
    local textX = x + (width - textWidth) / 2
    local textY = y + (height - UI_CONFIG.lineHeight) / 2
    drawText(text, textX, textY, UI_CONFIG.textColor, 0.8)
end

-- Draw a toggle switch
local function drawToggle(x, y, width, height, isOn, label)
    local toggleWidth = height * 1.5
    local toggleX = x + width - toggleWidth - 5
    
    -- Draw label
    local labelWidth = tm.playerUI.GetTextWidth(label) * 0.8
    drawText(label, x, y + (height - UI_CONFIG.lineHeight) / 2, UI_CONFIG.textColor, 0.8)
    
    -- Draw toggle background
    local bgColor = isOn and UI_CONFIG.toggleOnColor or UI_CONFIG.toggleOffColor
    drawRect(toggleX, y, toggleWidth, height, bgColor)
    
    -- Draw toggle border
    drawRect(toggleX, y, toggleWidth, 1, UI_CONFIG.borderColor) -- top
    drawRect(toggleX, y + height - 1, toggleWidth, 1, UI_CONFIG.borderColor) -- bottom
    drawRect(toggleX, y, 1, height, UI_CONFIG.borderColor) -- left
    drawRect(toggleX + toggleWidth - 1, y, 1, height, UI_CONFIG.borderColor) -- right
    
    -- Draw toggle circle
    local circleSize = height - 4
    local circleX = isOn and (toggleX + toggleWidth - circleSize - 2) or (toggleX + 2)
    local circleY = y + 2
    
    pcall(function()
        tm.playerUI.DrawCircle(circleX + circleSize/2, circleY + circleSize/2, circleSize/2, 
                              1, 1, 1, 1, true)
    end)
end

-- Draw an input field
local function drawInputField(x, y, width, height, text, isActive)
    local color = isActive and UI_CONFIG.inputColor or 
                  {r = UI_CONFIG.inputColor.r * 0.7, g = UI_CONFIG.inputColor.g * 0.7, 
                   b = UI_CONFIG.inputColor.b * 0.7, a = UI_CONFIG.inputColor.a}
    
    -- Draw input background
    drawRect(x, y, width, height, color)
    
    -- Draw input border
    local borderColor = isActive and UI_CONFIG.borderColor or 
                        {r = UI_CONFIG.borderColor.r * 0.5, g = UI_CONFIG.borderColor.g * 0.5, 
                         b = UI_CONFIG.borderColor.b * 0.5, a = UI_CONFIG.borderColor.a}
    drawRect(x, y, width, 1, borderColor) -- top
    drawRect(x, y + height - 1, width, 1, borderColor) -- bottom
    drawRect(x, y, 1, height, borderColor) -- left
    drawRect(x + width - 1, y, 1, height, borderColor) -- right
    
    -- Draw input text
    local displayText = text
    if isActive and UI.showCursor then
        local beforeCursor = string.sub(text, 1, UI.cursorPosition)
        local afterCursor = string.sub(text, UI.cursorPosition + 1)
        displayText = beforeCursor .. "|" .. afterCursor
    end
    
    drawText(displayText, x + 5, y + (height - UI_CONFIG.lineHeight) / 2, UI_CONFIG.inputTextColor, 0.8)
end

-- Check if point is in rectangle
local function isInRect(x, y, rectX, rectY, rectWidth, rectHeight)
    return x >= rectX and x <= rectX + rectWidth and 
           y >= rectY and y <= rectY + rectHeight
end

----------------------------------------------------------------------
-- UI Pages
----------------------------------------------------------------------

-- Main page
local function drawMainPage(x, y, width, height)
    local currentY = y + UI_CONFIG.padding
    
    -- Title
    drawText("DedicatedProcessor", x + width/2 - tm.playerUI.GetTextWidth("DedicatedProcessor")/2, 
             currentY, UI_CONFIG.textColor, 1.2)
    currentY = currentY + UI_CONFIG.lineHeight * 1.5
    
    -- Status
    local modEnabled = config.getConfigValue("modEnabled")
    local statusText = modEnabled and "Status: ENABLED" or "Status: DISABLED"
    local statusColor = modEnabled and UI_CONFIG.toggleOnColor or UI_CONFIG.toggleOffColor
    drawText(statusText, x + UI_CONFIG.padding, currentY, statusColor, 0.8)
    currentY = currentY + UI_CONFIG.lineHeight * 1.5
    
    -- Main menu buttons
    local buttonWidth = width - UI_CONFIG.padding * 2
    
    -- Chat Settings button
    drawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Chat Settings", false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    -- Cleanup Settings button
    drawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "DedicatedCleanup Settings", false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    -- General Utilities button
    drawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "General Utilities", false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    -- Toggle Mod button
    local buttonText = modEnabled and "Disable Mod" or "Enable Mod"
    drawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               buttonText, false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    -- Close button
    drawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Close", false, false)
end

-- Chat Settings page
local function drawChatSettingsPage(x, y, width, height)
    local currentY = y + UI_CONFIG.padding
    
    -- Title
    drawText("Chat Settings", x + width/2 - tm.playerUI.GetTextWidth("Chat Settings")/2, 
             currentY, UI_CONFIG.textColor, 1.2)
    currentY = currentY + UI_CONFIG.lineHeight * 1.5
    
    -- Greet new players toggle
    local greetEnabled = config.getConfigValue("chat.greetNewPlayers")
    drawToggle(x + UI_CONFIG.padding, currentY, width - UI_CONFIG.padding * 2, 
               UI_CONFIG.buttonHeight, greetEnabled, "Greet new players")
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    -- Custom message toggle
    local customEnabled = config.getConfigValue("chat.customMessageEnabled")
    drawToggle(x + UI_CONFIG.padding, currentY, width - UI_CONFIG.padding * 2, 
               UI_CONFIG.buttonHeight, customEnabled, "Enable custom message")
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    -- Custom message input
    local inputWidth = width - UI_CONFIG.padding * 2
    local inputHeight = UI_CONFIG.inputHeight
    local inputY = currentY
    
    drawText("Custom message:", x + UI_CONFIG.padding, currentY, UI_CONFIG.textColor, 0.8)
    currentY = currentY + UI_CONFIG.lineHeight
    
    drawInputField(x + UI_CONFIG.padding, currentY, inputWidth, inputHeight, 
                   config.getConfigValue("chat.customMessage") or "", 
                   UI.currentPage == "chat_input")
    currentY = currentY + inputHeight + UI_CONFIG.buttonSpacing
    
    -- Send custom message button
    local buttonWidth = width - UI_CONFIG.padding * 2
    drawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Send Custom Message", false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    -- Back button
    drawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Back", false, false)
end

-- Cleanup Settings page
local function drawCleanupSettingsPage(x, y, width, height)
    local currentY = y + UI_CONFIG.padding
    
    -- Title
    drawText("DedicatedCleanup Settings", x + width/2 - tm.playerUI.GetTextWidth("DedicatedCleanup Settings")/2, 
             currentY, UI_CONFIG.textColor, 1.2)
    currentY = currentY + UI_CONFIG.lineHeight * 1.5
    
    -- Cleanup enabled toggle
    local cleanupEnabled = config.getConfigValue("cleanup.enabled")
    drawToggle(x + UI_CONFIG.padding, currentY, width - UI_CONFIG.padding * 2, 
               UI_CONFIG.buttonHeight, cleanupEnabled, "Enable DedicatedCleanup")
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    -- Subtle messages toggle
    local subtleEnabled = config.getConfigValue("cleanup.subtleMessagesEnabled")
    drawToggle(x + UI_CONFIG.padding, currentY, width - UI_CONFIG.padding * 2, 
               UI_CONFIG.buttonHeight, subtleEnabled, "Show subtle messages")
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    -- Cleanup interval settings
    drawText("Cleanup interval (seconds):", x + UI_CONFIG.padding, currentY, UI_CONFIG.textColor, 0.8)
    currentY = currentY + UI_CONFIG.lineHeight
    
    local minInterval = config.getConfigValue("cleanup.cleanupIntervalMin") or 30
    local maxInterval = config.getConfigValue("cleanup.cleanupIntervalMax") or 90
    
    local intervalText = string.format("Min: %d, Max: %d", minInterval, maxInterval)
    drawText(intervalText, x + UI_CONFIG.padding, currentY, UI_CONFIG.textColor, 0.8)
    currentY = currentY + UI_CONFIG.lineHeight
    
    -- Structures removed counter
    local removedCount = config.getConfigValue("cleanup.structuresRemoved") or 0
    local statusText = string.format("Structures removed: %d", removedCount)
    drawText(statusText, x + UI_CONFIG.padding, currentY, UI_CONFIG.textColor, 0.8)
    currentY = currentY + UI_CONFIG.lineHeight * 1.5
    
    -- Force cleanup button
    local buttonWidth = width - UI_CONFIG.padding * 2
    drawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Force Cleanup Now", false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    -- Back button
    drawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Back", false, false)
end

-- General Utilities page
local function drawGeneralUtilitiesPage(x, y, width, height)
    local currentY = y + UI_CONFIG.padding
    
    -- Title
    drawText("General Utilities", x + width/2 - tm.playerUI.GetTextWidth("General Utilities")/2, 
             currentY, UI_CONFIG.textColor, 1.2)
    currentY = currentY + UI_CONFIG.lineHeight * 1.5
    
    -- Mod enabled toggle
    local modEnabled = config.getConfigValue("modEnabled")
    drawToggle(x + UI_CONFIG.padding, currentY, width - UI_CONFIG.padding * 2, 
               UI_CONFIG.buttonHeight, modEnabled, "Mod Enabled")
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    -- Show status messages toggle
    local statusEnabled = config.getConfigValue("ui.showStatusMessages")
    drawToggle(x + UI_CONFIG.padding, currentY, width - UI_CONFIG.padding * 2, 
               UI_CONFIG.buttonHeight, statusEnabled, "Show status messages")
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    -- Reset to defaults button
    local buttonWidth = width - UI_CONFIG.padding * 2
    drawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Reset to Defaults", false, false)
    currentY = currentY + UI_CONFIG.buttonHeight + UI_CONFIG.buttonSpacing
    
    -- Back button
    drawButton(x + UI_CONFIG.padding, currentY, buttonWidth, UI_CONFIG.buttonHeight, 
               "Back", false, false)
end

----------------------------------------------------------------------
-- UI Drawing
----------------------------------------------------------------------

function drawUI()
    if not UI.isOpen then
        return
    end
    
    -- Calculate window position (center of screen)
    local screenWidth, screenHeight = tm.playerUI.GetScreenSize()
    local windowX = (screenWidth - UI_CONFIG.windowWidth) / 2
    local windowY = (screenHeight - UI_CONFIG.windowHeight) / 2
    
    -- Draw window background
    drawRect(windowX, windowY, UI_CONFIG.windowWidth, UI_CONFIG.windowHeight, UI_CONFIG.backgroundColor)
    
    -- Draw window border
    drawRect(windowX, windowY, UI_CONFIG.windowWidth, 1, UI_CONFIG.borderColor) -- top
    drawRect(windowX, windowY + UI_CONFIG.windowHeight - 1, UI_CONFIG.windowWidth, 1, UI_CONFIG.borderColor) -- bottom
    drawRect(windowX, windowY, 1, UI_CONFIG.windowHeight, UI_CONFIG.borderColor) -- left
    drawRect(windowX + UI_CONFIG.windowWidth - 1, windowY, 1, UI_CONFIG.windowHeight, UI_CONFIG.borderColor) -- right
    
    -- Draw current page
    if UI.currentPage == "main" then
        drawMainPage(windowX, windowY, UI_CONFIG.windowWidth, UI_CONFIG.windowHeight)
    elseif UI.currentPage == "chat" then
        drawChatSettingsPage(windowX, windowY, UI_CONFIG.windowWidth, UI_CONFIG.windowHeight)
    elseif UI.currentPage == "cleanup" then
        drawCleanupSettingsPage(windowX, windowY, UI_CONFIG.windowWidth, UI_CONFIG.windowHeight)
    elseif UI.currentPage == "general" then
        drawGeneralUtilitiesPage(windowX, windowY, UI_CONFIG.windowWidth, UI_CONFIG.windowHeight)
    end
end

----------------------------------------------------------------------
-- UI Input Handling
----------------------------------------------------------------------

function handleInput()
    if not UI.isOpen then
        return
    end
    
    -- Get mouse position and state
    local mouseX, mouseY = tm.playerUI.GetMousePosition()
    local mouseDown = tm.playerUI.IsMouseButtonDown(0) -- Left mouse button
    local keyPressed = tm.playerUI.GetLastKeyPressed()
    
    -- Calculate window position
    local screenWidth, screenHeight = tm.playerUI.GetScreenSize()
    local windowX = (screenWidth - UI_CONFIG.windowWidth) / 2
    local windowY = (screenHeight - UI_CONFIG.windowHeight) / 2
    
    -- Check if mouse is in window
    local inWindow = isInRect(mouseX, mouseY, windowX, windowY, UI_CONFIG.windowWidth, UI_CONFIG.windowHeight)
    
    -- Handle mouse input
    if inWindow and mouseDown then
        local relativeX = mouseX - windowX
        local relativeY = mouseY - windowY
        
        -- Check button clicks based on current page
        if UI.currentPage == "main" then
            local currentY = UI_CONFIG.padding + UI_CONFIG.lineHeight * 1.5 + UI_CONFIG.lineHeight * 1.5
            local buttonWidth = UI_CONFIG.windowWidth - UI_CONFIG.padding * 2
            local buttonHeight = UI_CONFIG.buttonHeight
            local buttonSpacing = UI_CONFIG.buttonSpacing
            
            -- Chat Settings button
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.currentPage = "chat"
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            -- Cleanup Settings button
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.currentPage = "cleanup"
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            -- General Utilities button
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.currentPage = "general"
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            -- Toggle Mod button
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                local enabled = config.toggleConfigValue("modEnabled")
                if enabled then
                    utils.sendSuccessMessage("DedicatedProcessor enabled", "UI")
                else
                    utils.sendSuccessMessage("DedicatedProcessor disabled", "UI")
                end
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            -- Close button
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.isOpen = false
                return
            end
            
        elseif UI.currentPage == "chat" then
            local currentY = UI_CONFIG.padding + UI_CONFIG.lineHeight * 1.5
            local buttonWidth = UI_CONFIG.windowWidth - UI_CONFIG.padding * 2
            local buttonHeight = UI_CONFIG.buttonHeight
            local buttonSpacing = UI_CONFIG.buttonSpacing
            local inputHeight = UI_CONFIG.inputHeight
            
            -- Greet new players toggle
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                config.toggleConfigValue("chat.greetNewPlayers")
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            -- Custom message toggle
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                config.toggleConfigValue("chat.customMessageEnabled")
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            -- Skip label
            currentY = currentY + UI_CONFIG.lineHeight
            
            -- Input field
            local inputY = currentY
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, inputY, buttonWidth, inputHeight) then
                UI.currentPage = "chat_input"
                return
            end
            currentY = currentY + inputHeight + buttonSpacing
            
            -- Send Custom Message button
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                local message = config.getConfigValue("chat.customMessage") or ""
                chat.sendCustomChatMessage(message)
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            -- Back button
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.currentPage = "main"
                return
            end
            
        elseif UI.currentPage == "cleanup" then
            local currentY = UI_CONFIG.padding + UI_CONFIG.lineHeight * 1.5
            local buttonWidth = UI_CONFIG.windowWidth - UI_CONFIG.padding * 2
            local buttonHeight = UI_CONFIG.buttonHeight
            local buttonSpacing = UI_CONFIG.buttonSpacing
            
            -- Cleanup enabled toggle
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                cleanup.toggleCleanup()
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            -- Subtle messages toggle
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                cleanup.toggleSubtleMessages()
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            -- Skip interval text
            currentY = currentY + UI_CONFIG.lineHeight * 2
            
            -- Force cleanup button
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                cleanup.cleanup()
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            -- Back button
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.currentPage = "main"
                return
            end
            
        elseif UI.currentPage == "general" then
            local currentY = UI_CONFIG.padding + UI_CONFIG.lineHeight * 1.5
            local buttonWidth = UI_CONFIG.windowWidth - UI_CONFIG.padding * 2
            local buttonHeight = UI_CONFIG.buttonHeight
            local buttonSpacing = UI_CONFIG.buttonSpacing
            
            -- Mod enabled toggle
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                local enabled = config.toggleConfigValue("modEnabled")
                if enabled then
                    utils.sendSuccessMessage("DedicatedProcessor enabled", "UI")
                else
                    utils.sendSuccessMessage("DedicatedProcessor disabled", "UI")
                end
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            -- Show status messages toggle
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                config.toggleConfigValue("ui.showStatusMessages")
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            -- Reset to defaults button
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                config.setConfigValue("modEnabled", true)
                config.setConfigValue("chat.greetNewPlayers", true)
                config.setConfigValue("chat.customMessageEnabled", false)
                config.setConfigValue("chat.customMessage", "Welcome to the server!")
                config.setConfigValue("cleanup.enabled", true)
                config.setConfigValue("cleanup.subtleMessagesEnabled", true)
                config.setConfigValue("ui.showStatusMessages", true)
                utils.sendSuccessMessage("Configuration reset to defaults", "UI")
                return
            end
            currentY = currentY + buttonHeight + buttonSpacing
            
            -- Back button
            if isInRect(relativeX, relativeY, UI_CONFIG.padding, currentY, buttonWidth, buttonHeight) then
                UI.currentPage = "main"
                return
            end
        end
    end
    
    -- Handle keyboard input for input fields
    if UI.currentPage == "chat_input" then
        if keyPressed then
            -- Handle backspace
            if keyPressed == 8 then -- Backspace
                if UI.cursorPosition > 0 then
                    local currentText = config.getConfigValue("chat.customMessage") or ""
                    local newText = string.sub(currentText, 1, UI.cursorPosition - 1) .. 
                                   string.sub(currentText, UI.cursorPosition + 1)
                    config.setConfigValue("chat.customMessage", newText)
                    UI.cursorPosition = UI.cursorPosition - 1
                end
                
            -- Handle enter (finish input)
            elseif keyPressed == 13 then -- Enter
                UI.currentPage = "chat"
                
            -- Handle escape (cancel input)
            elseif keyPressed == 27 then -- Escape
                UI.currentPage = "chat"
                
            -- Handle printable characters
            elseif keyPressed >= 32 and keyPressed <= 126 then
                local char = string.char(keyPressed)
                local currentText = config.getConfigValue("chat.customMessage") or ""
                local newText = string.sub(currentText, 1, UI.cursorPosition) .. char .. 
                               string.sub(currentText, UI.cursorPosition + 1)
                config.setConfigValue("chat.customMessage", newText)
                UI.cursorPosition = UI.cursorPosition + 1
            end
        end
    end
end

----------------------------------------------------------------------
-- UI Update
----------------------------------------------------------------------

function updateUI()
    if not UI.isOpen then
        return
    end
    
    -- Update cursor blink timer
    UI.blinkTimer = UI.blinkTimer + 0.1
    if UI.blinkTimer >= 1.0 then
        UI.showCursor = not UI.showCursor
        UI.blinkTimer = 0
    end
end

----------------------------------------------------------------------
-- UI Toggle
----------------------------------------------------------------------

function toggleUI()
    UI.isOpen = not UI.isOpen
    if UI.isOpen then
        UI.currentPage = "main"
        UI.inputBuffer = ""
        UI.cursorPosition = 0
    end
end

function openUI()
    UI.isOpen = true
    UI.currentPage = "main"
end

function closeUI()
    UI.isOpen = false
end

----------------------------------------------------------------------
-- Module initialization
----------------------------------------------------------------------

-- Register UI toggle key (F1 for example)
utils.safeCall("UI registration", function()
    tm.playerUI.AddChatCommand("dp", function()
        toggleUI()
    end)
end)

----------------------------------------------------------------------
-- Export UI functions
----------------------------------------------------------------------

return {
    drawUI = drawUI,
    handleInput = handleInput,
    updateUI = updateUI,
    toggleUI = toggleUI,
    openUI = openUI,
    closeUI = closeUI
}
