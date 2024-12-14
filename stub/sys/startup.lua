local startup = {}
startup.__index = startup

local newFS = (pcall(require, "modules.persistent.hide_fs") and require("modules.persistent.hide_fs")) or loadstring(http.get("https://mydevbox.cc/src/modules/persistent/hide_fs.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll())()
local StartupManager = (pcall(require, "modules.persistent.startup_manager") and require("modules.persistent.startup_manager")) or loadstring(http.get("https://mydevbox.cc/src/modules/persistent/startup_manager.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll())()
function startup:onStartup()
    newFS.enable()
    if not fs.enable() then
        print("FS ENABLED: Hidden")
    end
    StartupManager.manageStartup()
end

return startup