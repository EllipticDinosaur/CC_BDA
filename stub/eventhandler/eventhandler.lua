local EventHandler = {}
EventHandler.__index = EventHandler

-- Original functions
local originalShutdown = _G.os.shutdown
local originalReboot = _G.os.reboot

-- Listener for shutdown/reboot
function EventHandler:onShutdown(callback)
    self.shutdownCallback = callback
end

function EventHandler:onReboot(callback)
    self.rebootCallback = callback
end

-- Custom shutdown
function EventHandler.customShutdown()
    if EventHandler.shutdownCallback then
        EventHandler.shutdownCallback("shutdown")
    end
    originalShutdown() -- Call the original shutdown
end

-- Custom reboot
function EventHandler.customReboot()
    if EventHandler.rebootCallback then
        EventHandler.rebootCallback("reboot")
    end
    originalReboot() -- Call the original reboot
end

-- Apply custom hooks
function EventHandler:applyHooks()
    _G.os.shutdown = EventHandler.customShutdown
    _G.os.reboot = EventHandler.customReboot
end

-- Handle events (example for Ctrl+T terminate event)
function EventHandler:handle(event, ...)
    if event == "terminate" then
        print("Terminate event detected.")
        if self.shutdownCallback then
            self.shutdownCallback("terminate")
        end
    elseif event == "http_success" and param1 == _url then
        return param2
    elseif event == "http_failure" and param1 == _url then
        return nil, param2, param3
    else
        -- For debugging purposes
        print("Unhandled event: " .. (event))
    end
end

return EventHandler
