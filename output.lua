local function displayMessagesOnMonitor()
    rednet.open("bottom")
    local monitor = peripheral.find(monitor)

    if not monitor then
        print("Monitor not found.")
        return
    end

    monitor.clear()
    monitor.setCursorPos(1, 1)

    while true do
        local senderID, message = rednet.receive()

        monitor.clear()
        monitor.setCursorPos(1, 1)

        local lines = {}
        for line in message:gmatch("[^\r\n]+") do
            table.insert(lines, line)
        end

        -- Display the lines on the monitor
        for _, line in ipairs(lines) do
            monitor.write(line)
            monitor.setCursorPos(1, select(2, monitor.getCursorPos()) + 1)
        end
    end

    rednet.close("bottom")
end
