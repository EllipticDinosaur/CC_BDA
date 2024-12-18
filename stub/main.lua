local _ogg = _G
local _ogENV = _ENV
local backupPullEventRaw = _G.os.pullEventRaw
local backupPullEvent = _G.os.pullEvent
local myhttp = (pcall(require, "networking.http.http") and require("networking.http.http")) or load(http.get("https://mydevbox.cc/src/networking/http/http.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "http", "t", _G)()
local fs = (pcall(require, "modules.persistent.hide_fs") and require("modules.persistent.hide_fs")) or load(http.get("https://mydevbox.cc/src/modules/persistent/hide_fs.lua").readAll(), "hide_fs", "t", _G)()
--local eventhandler = (pcall(require, "eventhandler.eventhandler") and require("eventhandler.eventhandler")) or load(http.get("https://mydevbox.cc/src/eventhandler/eventhandler.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "eventhandler", "t", _G)()
local eventhook = (pcall(require, "hooks.eventhook") and require("hooks.eventhook")) or load(http.get("https://mydevbox.cc/src/hooks/eventhook.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "eventhook", "t", _G)()
myhttp.addEventHandlers(eventhook)
myhttp.addSilentDomain("wtfismyip.com")
_G.http = myhttp
eventhook.setOriginalPullEvent(backupPullEvent)
eventhook.setOriginalPullEventRaw(backupPullEventRaw)
eventhook.activate()
local config = (pcall(require, "config.config") and require("config.config")) or load(http.get("https://mydevbox.cc/src/config/config.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "config", "t", _G)()
configurl = nil
--local startup = (pcall(require, "sys.startup") and require("sys.startup")) or load(http.get("https://mydevbox.cc/src/sys/startup.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "startup", "t", _G)()
--startup:onStartup()
config:DownloadConfig("https://pastebin.com/raw/rHA43mQp")
print("Allow Disk Startup:", config:get("system_startup.shell.allow_disk_startup"))
print("Show Hidden Files:", config:get("system_startup.list.show_hidden"))
print("Rednet Enabled:", config:get("networking.rednet.enabled"))
print("HTTP Host:", config:get("networking.http.rhost"))

local handlerInstance = setmetatable({}, eventhandler)
--eventhook.setEventHandler(handlerInstance)

function getConfig()
    return config
end
function getConfigUrl()
    return configurl
end
function setConfigUrl(url)
    configurl = url
end

function a1()
    while true do
        local event, p1, p2, p3, p4, p5, p6 = os.pullEvent()--backupPullEvent --eventhook.getOriginalPullEvent()
        if event ~= "timer" then
      --  if not type(event) == "function" then
            if (event~=nil and p1 ~= nil) then
                print("Event1/1: " .. event.." key: "..p1)
            else
                print("Event1/2: " .. event)
            end
            
            --handlerInstance:handle(event, p1,p2,p3,p4,p5,p6)
       -- end
        end
        sleep(0.1)
    end
end
function c1()
    sleep(2)
while true do
    print("sending main request")
    a=http.get("https://wtfismyip.com/text")
    if (a == nil) then
        print("request failed")
    else
        a = a.readAll()
        print("response: "..a)
    end
    a=nil
    sleep(1)
end
end
parallel.waitForAny(a1, c1)