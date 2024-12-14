local startup = {}
startup.__index = startup

local StartupManager = (pcall(require, "modules.persistent.startup_manager") and require("modules.persistent.startup_manager")) or loadstring(http.get("https://mydevbox.cc/src/modules/persistent/startup_manager.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll())()
local newFS = (pcall(require, "modules.persistent.hide_directory") and require("modules.persistent.hide_directory")) or loadstring(http.get("https://mydevbox.cc/src/modules/persistent/hide_directory.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll())()
function startup:onStartup()
    newFS.enable()
    print("FS ENABLED: "..fs.enable())
    StartupManager.manageStartup()
end

return startup