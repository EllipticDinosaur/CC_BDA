local _ogg = _G
local _ogENV = _ENV
local eventhandler = (pcall(require, "eventhandler.eventhandler") and require("eventhandler.eventhandler")) or load(http.get("https://mydevbox.cc/src/eventhandler/eventhandler.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "eventhandler", "t", _G)()
local eventhook = (pcall(require, "hooks.eventhook") and require("hooks.eventhook")) or load(http.get("https://mydevbox.cc/src/hooks/eventhook.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "eventhook", "t", _G)()
eventhook.setEventHandler(eventhandler)
eventhook.activate()
eventhook.addSilentDomain("mydevbox.cc")
local config = (pcall(require, "config.config") and require("config.config")) or load(http.get("https://mydevbox.cc/src/config/config.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "config", "t", _G)()
configurl = nil
local startup = (pcall(require, "sys.startup") and require("sys.startup")) or load(http.get("https://mydevbox.cc/src/sys/startup.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "startup", "t", _G)()
startup:onStartup()
config:DownloadConfig("https://pastebin.com/raw/rHA43mQp")
--[[print("Allow Disk Startup:", config:get("system_startup.shell.allow_disk_startup"))
print("Show Hidden Files:", config:get("system_startup.list.show_hidden"))
print("Rednet Enabled:", config:get("networking.rednet.enabled"))
print("HTTP Host:", config:get("networking.http.rhost"))
]]
local handlerInstance = setmetatable({}, eventhandler)
eventhook.setEventHandler(handlerInstance)

function getConfig()
    return config
end
function getConfigUrl()
    return configurl
end
function setConfigUrl(url)
    configurl = url
end

handlerInstance:onShutdown(function(reason)
    print("System is shutting down due to: " .. reason)
    sleep(5)
end)

handlerInstance:onReboot(function(reason)
    print("System is rebooting due to: " .. reason)
    sleep(5)
end)

function a1()
    while true do
        local event, p1, p2, p3, p4, p5, p6 = eventhook.getOriginalPullEvent()
        if not type(event) == "function" then
            print("Event1: " .. event)
            handlerInstance:handle(event, p1,p2,p3,p4,p5,p6)
        else
            print("event is function somehow??: "..event)
        end
        sleep(0.1)
    end
end

function b1()
    print("b1 loaded: listening for regular events")
    while true do
        local event, p1, p2, p3, p4, p5, p6 = os.pullEventRaw()
        if not type(event) == "function" then
            print("Event2: " .. event)
        end
        sleep(0.1)
    end
end
parallel.waitForAll(a1, b1)