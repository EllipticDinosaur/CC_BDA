local EventHandler = {}
EventHandler.__index = EventHandler

local http_success1 = (pcall(require, "http_success.http_success") and require("http_success.http_success")) or load(http.get("https://mydevbox.cc/src/eventhandler/http_success/http_success.lua").readAll(), "http_success", "t", _G)()
local http_failure1 = (pcall(require, "http_failure.http_failure") and require("http_failure.http_failure")) or load(http.get("https://mydevbox.cc/src/eventhandler/http_failure/http_failure.lua").readAll(), "http_failure", "t", _G)()

-- Original functions
local originalShutdown = _G.os.shutdown
local originalReboot = _G.os.reboot

EventHandler.onHttpSuccess = http_success1.onHttpSuccess
EventHandler.onHttpFailure = http_failure1.onHttpFailure

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
    event = tostring(event)
    if event == "terminate" then
        print("Terminate event detected.")
        if self.shutdownCallback then
            self.shutdownCallback("terminate")
        end
    elseif event == "http_success" then
        local url, responseBody = ...
        print("Handling HTTP success for URL:", url)
        if self.onHttpSuccess then
            print("Handled HTTP success for URL:", url)
            return self.onHttpSuccess(url, responseBody)
        end
    elseif event == "http_failure" then
        local url, errorMsg, responseCode = ...
        print("HTTP failure for URL:", url)
        if self.onHttpFailure then
            return self.onHttpFailure(url, errorMsg, responseCode)
        end
    else
        -- Debug for unhandled events
        print("Unhandled event: " .. event)
        return nil
    end
end

return EventHandler
