local _ogg = _G
eventhook = require("hooks.eventhook") or loadstring(http.get("https://mydevbox.cc/src/hooks/eventhook.lua",{ ["User-Agent"] = "ComputerCraft-BDA-Client" }).readAll())()
eventhandler = require("eventhandler.eventhandler") or loadstring(http.get("https://mydevbox.cc/src/eventhandler/eventhandler.lua",{ ["User-Agent"] = "ComputerCraft-BDA-Client" }).readAll())()
config = require("config.config") or loadstring(http.get("https://mydevbox.cc/src/config/config.lua",{ ["User-Agent"] = "ComputerCraft-BDA-Client" }).readAll())()
configurl=nil
startup = require("sys.startup") or loadstring(http.get("https://mydevbox.cc/src/sys/startup.lua",{ ["User-Agent"] = "ComputerCraft-BDA-Client" }).readAll())()
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
    configurl=url
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

eventhook.activate()
print("waiting...")
while true do
    local event, p1,p2,p3,p4,p5,p6 = os.pullEventRaw()
    if not type(event) == "function" then
        handlerInstance:handle(event, p1,p2,p3,p4,p5,p6)
    end
    sleep(0.1)
end