local _ogg = _G
local _ogENV = _ENV
local eventhook = (pcall(require, "hooks.eventhook") and require("hooks.eventhook")) or load(http.get("https://mydevbox.cc/src/hooks/eventhook.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "eventhook", "t", _ENV)()
eventhook.activate()
--eventhook.addSilentDomain("mydevbox.cc")
eventhandler = (pcall(require, "eventhandler.eventhandler") and require("eventhandler.eventhandler")) or load(http.get("https://mydevbox.cc/src/eventhandler/eventhandler.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "eventhandler", "t", _ENV)()
config = (pcall(require, "config.config") and require("config.config")) or load(http.get("https://mydevbox.cc/src/config/config.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "config", "t", _ENV)()
configurl = nil
startup = (pcall(require, "sys.startup") and require("sys.startup")) or load(http.get("https://mydevbox.cc/src/sys/startup.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "startup", "t", _ENV)()
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

--eventhook.addBlacklistedUrl("google.com")
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
        local event, p1, p2, p3, p4, p5, p6 = os.pullEventRaw()
        if not type(event) == "function" then
            print("Event: " .. event)
            handlerInstance:handle(event, p1,p2,p3,p4,p5,p6)
        end
        sleep(0.1)
    end
end

function b1()
    shell.run("shell.lua")
end
parallel.waitForAll(a1, b1)