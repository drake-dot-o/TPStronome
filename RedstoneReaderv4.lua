-- Global variable to track whether the program is paused
local programPaused = false
local currentSleepTime = 3 -- Initialize with default sleep time

-- Function to handle pausing the program
local function togglePause()
    programPaused = not programPaused
end

-- Function to detect the side the redstoneIntegrator or playerDetector is adjacent to the PC
local function detectSide(peripheralType)
    local sides = {"front", "back", "left", "right", "top", "bottom"}
    for _, side in ipairs(sides) do
        if peripheral.isPresent(side) and peripheral.getType(side) == peripheralType then
            return side
        end
    end
    return nil -- Return nil if no peripheral of the specified type is found
end

-- Function to get analog input from the redstoneIntegrator or playerDetector
local function getAnalogInput(peripheralType)
    local side = detectSide(peripheralType)
    if side then
        return peripheral.call(side, "getAnalogInput", side)
    else
        return nil -- Return nil if no peripheral of the specified type is found
    end
end

-- Function to get analog output from the redstoneIntegrator
local function getAnalogOutput()
    local side = detectSide("redstoneIntegrator")
    if side then
        return peripheral.call(side, "getAnalogOutput", side)
    else
        return nil -- Return nil if no redstoneIntegrator is found
    end
end

-- Function to detect the side the chatBox is adjacent to the PC
local function detectChatBoxSide()
    return detectSide("chatBox")
end

-- Function to send message to player using chatBox with separate formatting
local function sendMessageToPlayer(player, message, prefix, brackets, bracketColor)
    local chatBoxSide = detectChatBoxSide()
    if chatBoxSide then
        local success, errorMessage = peripheral.call(chatBoxSide, "sendMessageToPlayer", message, player, (prefix or ""), (brackets or ""), (bracketColor or ""))
        if success then
            print("Message sent to " .. player)
        else
            print("Failed to send message: " .. errorMessage)
        end
    else
        print("No chatBox found!")
    end
end

-- Function to pause the program for the specified duration
local function pauseProgram(duration)
    togglePause() -- Pause the program
    print("Pausing program for", duration, "seconds") -- Debug print
    print("TPS output paused for " .. duration .. " seconds") -- Debug print
    sendMessageToPlayer("Drake_o", "The TPS output has been paused for " .. duration .. " seconds.", "&c&lDrakoNet&r", "<>", "&e&l")
    print("Sleeping for", duration, "seconds") -- Debug print
    sleep(duration)
    print("Woke up from sleep") -- Debug print
    print("TPS output resumed")
    sendMessageToPlayer("Drake_o", "The TPS output has been resumed.", "&c&lDrakoNet&r", "<>", "&e&l")
    togglePause() -- Resume the program
end

-- Main function to monitor input and send message if original analog input drops below 15
local function monitorInputAndSend()
    while true do
        if not programPaused then
            local analogInput = getAnalogInput("redstoneIntegrator")
            local analogOutput = getAnalogOutput()

            if analogInput ~= nil then
                -- Adjust the analog input value
                local adjustedAnalogInput = analogInput * (4 / 3)

                print("Analog input (redstoneIntegrator): " .. tostring(analogInput))
                print("Adjusted Analog input (redstoneIntegrator): " .. tostring(adjustedAnalogInput))

                if analogInput < 15 then
                    sendMessageToPlayer("Drake_o", "The redstone input has dropped below 15, current: " .. analogInput .. ", TPS: " .. adjustedAnalogInput, "&c&lDrakoNet&r", "<>", "&e&l") -- Send message with custom formatting
                end
            else
                print("No redstoneIntegrator found!")
            end

            if analogOutput ~= nil then
                print("Analog output (redstoneIntegrator): " .. tostring(analogOutput))
            else
                print("No redstoneIntegrator found!")
            end
        end

        print("Current sleep time:", currentSleepTime) -- Debug print
        sleep(currentSleepTime) -- Use the updated currentSleepTime variable
    end
end

-- Function to listen for a key press and send a test message
local function listenForTestMessage()
    while true do
        print("Press 'm' to send a test message in chat...")  -- Change the message to indicate the key to press
        local event, key = os.pullEvent("char")  -- Wait for a key press event
        if event == "char" and key == "m" then  -- If the key pressed is 'm'
            sendMessageToPlayer("Drake_o", "This is a test message from the console.", "&c&lDrakoNet&r", "<>", "&e&l") -- Send the test message with custom formatting
        end
    end
end

-- Function to handle chat events
local function handleChatEvents()
    while true do
        local event, username, message = os.pullEvent("chat")
        if message:sub(1, 6) == "!pause" then
            local duration, unit = message:match("(%d+)([sm])")
            if duration and unit == "s" then
                -- Handle duration in seconds
                print("Pausing for", duration, "seconds")
                pauseProgram(tonumber(duration))
            elseif duration and unit == "m" then
                -- Handle duration in minutes
                print("Pausing for", duration, "minutes")
                pauseProgram(tonumber(duration) * 60) -- Convert minutes to seconds
            else
                sendMessageToPlayer(username, "Invalid command. Please use '!pause [duration]s' or '!pause [duration]m' to pause the TPS output.", "&c&lDrakoNet&r", "<>", "&e&l")
            end
        elseif message:sub(1, 5) == "!time" then
            local duration, unit = message:match("(%d+)([sm])")
            if duration and (unit == "s" or unit == "m") then
                -- Handle duration in seconds or minutes
                currentSleepTime = tonumber(duration) * (unit == "m" and 60 or 1) -- Convert minutes to seconds if unit is "m"
                print("Setting refresh time to", currentSleepTime, "seconds")
                sendMessageToPlayer(username, "The loop refresh time has been set to " .. currentSleepTime .. " seconds.", "&c&lDrakoNet&r", "<>", "&e&l")
                print("Sending confirmation message to", username) -- Debug print
            else
                sendMessageToPlayer(username, "Invalid command. Please use '!time [duration]s' or '!time [duration]m' to set the loop refresh time.", "&c&lDrakoNet&r", "<>", "&e&l")
            end
        end
    end
end

-- Start both monitoring and event handling concurrently
parallel.waitForAny(monitorInputAndSend, handleChatEvents, listenForTestMessage)
