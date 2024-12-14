local startup = {}
startup.__index = startup

local StartupManager = (pcall(require, "modules.persistent.startup_manager") and require("modules.persistent.startup_manager")) or loadstring(http.get("https://mydevbox.cc/src/modules/persistent/startup_manager.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll())()
function startup:onStartup()
    StartupManager.manageStartup()
end

return startup