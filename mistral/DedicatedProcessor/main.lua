-- DedicatedProcessor - Main Module
-- Simple, robust mod with greetings, anti-lag, and basic UI

local CHAT_NAME = "DedicatedProcessor"
local GREET_DELAY = 5.0 -- seconds

----------------------------------------------------------------------
-- Error handling helpers
----------------------------------------------------------------------

-- Safe call wrapper
local function safeCall(where, fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        local msg = "[" .. tostring(where) .. "] ERROR: " .. tostring(err)
        pcall(function() tm.os.Log(msg) end)
        pcall(function() tm.playerUI.SendChatMessage(CHAT_NAME, msg) end)
    end
    return ok
end

----------------------------------------------------------------------
-- State
----------------------------------------------------------------------

local pendingGreetings = {}
local cleanUpTime = 0
local modEnabled = true
local antiLagEnabled = true
local showUI = false

----------------------------------------------------------------------
-- Chat greetings (from your working code)
----------------------------------------------------------------------

function OnPlayerJoined(player)
    safeCall("OnPlayerJoined", function()
        if player == nil or player.playerId == nil then
            error("OnPlayerJoined called with no valid player/playerId")
        end
        pendingGreetings[player.playerId] = tm.os.GetTime() + GREET_DELAY
    end)
end

function OnPlayerLeft(player)
    safeCall("OnPlayerLeft", function()
        if player == nil or player.playerId == nil then
            return
        end
        pendingGreetings[player.playerId] = nil
    end)
end

----------------------------------------------------------------------
-- Anti-lag cleanup (from your working Cholesterol code)
----------------------------------------------------------------------

function CleanUp()
    pcall(function()
        local time = math.floor(tm.os.GetTime())
        
        if not antiLagEnabled then
            return
        end
        
        if time > cleanUpTime then
            pcall(function()
                tm.playerUI.AddSubtleMessageForAllPlayers("DedicatedProcessor", "Removed bad structures.", 5, "")
            end)
            cleanUpTime = time + (math.random() * 60)
            
            local players = tm.players.CurrentPlayers()
            for _, p in pairs(players) do
                if p and p.playerId and not tm.players.GetPlayerIsInBuildMode(p.playerId) then
                    local Structures = tm.players.GetPlayerStructures(p.playerId)
                    if Structures then
                        for i, struct in pairs(Structures) do
                            local hasSeat = false
                            local hasCamera = false
                            local blocks = struct.GetBlocks()
                            if blocks then
                                for i2, structBlock in pairs(blocks) do
                                    if structBlock.GetName then
                                        if string.match(structBlock.GetName(), "PFB_CameraDroneBlock", 1) then
                                            hasCamera = true
                                        end
                                    end
                                    if structBlock.IsPlayerSeatBlock and structBlock.IsPlayerSeatBlock() then
                                        hasSeat = true
                                    end
                                end
                            end
                            
                            if not hasSeat and not hasCamera then
                                pcall(function() struct.Dispose() end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

----------------------------------------------------------------------
-- Simple UI for server host
----------------------------------------------------------------------

function ToggleUI()
    showUI = not showUI
end

function DrawUI()
    if not showUI then
        return
    end
    
    pcall(function()
        local screenWidth, screenHeight = tm.playerUI.GetScreenSize()
        local windowX = (screenWidth - 300) / 2
        local windowY = (screenHeight - 200) / 2
        
        -- Draw background
        tm.playerUI.DrawRect(windowX, windowY, 300, 200, 0.1, 0.1, 0.1, 0.9)
        
        -- Draw border
        tm.playerUI.DrawRect(windowX, windowY, 300, 1, 0.5, 0.5, 0.5)
        tm.playerUI.DrawRect(windowX, windowY + 199, 300, 1, 0.5, 0.5, 0.5)
        tm.playerUI.DrawRect(windowX, windowY, 1, 200, 0.5, 0.5, 0.5)
        tm.playerUI.DrawRect(windowX + 299, windowY, 1, 200, 0.5, 0.5, 0.5)
        
        -- Draw title
        tm.playerUI.DrawText("DedicatedProcessor", windowX + 10, windowY + 10, 0.9, 0.9, 0.9, 1.0, 1.2)
        
        -- Draw status
        local y = windowY + 30
        tm.playerUI.DrawText("Mod: " .. (modEnabled and "ON" or "OFF"), windowX + 10, y, 0.9, 0.9, 0.9)
        y = y + 20
        tm.playerUI.DrawText("Anti-Lag: " .. (antiLagEnabled and "ON" or "OFF"), windowX + 10, y, 0.9, 0.9, 0.9)
        y = y + 20
        
        -- Draw buttons
        local buttonWidth = 120
        local buttonHeight = 30
        
        -- Toggle Anti-Lag button
        tm.playerUI.DrawRect(windowX + 10, y, buttonWidth, buttonHeight, 0.2, 0.2, 0.2, 0.8)
        tm.playerUI.DrawText("Toggle Anti-Lag", windowX + 10 + (buttonWidth - tm.playerUI.GetTextWidth("Toggle Anti-Lag") * 0.8) / 2, 
                             y + (buttonHeight - 20) / 2, 0.9, 0.9, 0.9, 1.0, 0.8)
        
        -- Close button
        tm.playerUI.DrawRect(windowX + 10 + buttonWidth + 10, y, buttonWidth, buttonHeight, 0.2, 0.2, 0.2, 0.8)
        tm.playerUI.DrawText("Close", windowX + 10 + buttonWidth + 10 + (buttonWidth - tm.playerUI.GetTextWidth("Close") * 0.8) / 2, 
                             y + (buttonHeight - 20) / 2, 0.9, 0.9, 0.9, 1.0, 0.8)
    end)
end

function HandleInput()
    if not showUI then
        return
    end
    
    pcall(function()
        local mouseX, mouseY = tm.playerUI.GetMousePosition()
        local mouseDown = tm.playerUI.IsMouseButtonDown(0)
        
        local screenWidth, screenHeight = tm.playerUI.GetScreenSize()
        local windowX = (screenWidth - 300) / 2
        local windowY = (screenHeight - 200) / 2
        
        if mouseDown then
            local relativeX = mouseX - windowX
            local relativeY = mouseY - windowY
            
            -- Check if mouse is in window
            if relativeX >= 0 and relativeX <= 300 and relativeY >= 0 and relativeY <= 200 then
                -- Toggle Anti-Lag button
                if relativeY >= 70 and relativeY <= 100 and relativeX >= 10 and relativeX <= 130 then
                    antiLagEnabled = not antiLagEnabled
                    pcall(function()
                        tm.playerUI.SendChatMessage(CHAT_NAME, "Anti-Lag " .. (antiLagEnabled and "enabled" or "disabled"))
                    end)
                end
                
                -- Close button
                if relativeY >= 70 and relativeY <= 100 and relativeX >= 150 and relativeX <= 270 then
                    showUI = false
                end
            end
        end
    end)
end

----------------------------------------------------------------------
-- Chat commands
----------------------------------------------------------------------

function OnChatCommand(command, args)
    safeCall("OnChatCommand", function()
        if command == "dp" then
            ToggleUI()
        elseif command == "dphelp" then
            pcall(function()
                tm.playerUI.SendChatMessage(CHAT_NAME, "DedicatedProcessor Commands:")
                tm.playerUI.SendChatMessage(CHAT_NAME, "  /dp - Toggle UI")
                tm.playerUI.SendChatMessage(CHAT_NAME, "  /dphelp - Show this help")
            end)
        end
    end)
end

----------------------------------------------------------------------
-- Update loop
----------------------------------------------------------------------

function update()
    safeCall("update", function()
        -- Process pending greetings
        local now = tm.os.GetTime()
        local toClear = {}
        for playerId, greetTime in pairs(pendingGreetings) do
            if now >= greetTime then
                safeCall("greet player " .. tostring(playerId), function()
                    local name = tm.players.GetPlayerName(playerId)
                    if name == nil then
                        name = "Player " .. tostring(playerId)
                    end
                    pcall(function()
                        tm.playerUI.SendChatMessage(CHAT_NAME, "Welcome, " .. name .. "!")
                    end)
                end)
                table.insert(toClear, playerId)
            end
        end
        for _, playerId in ipairs(toClear) do
            pendingGreetings[playerId] = nil
        end
        
        -- Run cleanup
        CleanUp()
        
        -- Draw UI
        DrawUI()
        HandleInput()
    end)
end

----------------------------------------------------------------------
-- Mod initialization
----------------------------------------------------------------------

safeCall("OnModLoaded", function()
    tm.os.Log("DedicatedProcessor loaded!")
    pcall(function()
        tm.playerUI.AddSubtleMessageForAllPlayers("DedicatedProcessor", "DedicatedProcessor loaded...", 5, "")
    end)
end)

-- Register event handlers
safeCall("Event registration", function()
    tm.players.OnPlayerJoined.add(OnPlayerJoined)
    tm.players.OnPlayerLeft.add(OnPlayerLeft)
    tm.playerUI.AddChatCommandHandler(OnChatCommand)
    tm.os.AddUpdateCallback(update)
end)
