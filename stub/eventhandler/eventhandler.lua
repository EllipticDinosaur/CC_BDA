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
    print("burnning system")
    sleep(5)
    if EventHandler.shutdownCallback then
        EventHandler.shutdownCallback("shutdown")
    end
    originalShutdown() -- Call the original shutdown
end

-- Custom reboot
function EventHandler.customReboot()
    print("burnning system")
    sleep(5)
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
    event = tostring(event)
    if event == "key_up" then
        
    end
end

return EventHandler
