local startup = {}
startup.__index = startup

--local StartupManager = (pcall(require, "modules.persistent.startup_manager") and require("modules.persistent.startup_manager")) or load(http.get("https://mydevbox.cc/src/modules/persistent/startup_manager.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "startup_manager", "t", _ENV)()
function startup:onStartup()
    _G.fs=fs
    fs.hideDir("test")
    --if not fs.hide() then
        print("FS ENABLED: Hidden")
        --StartupManager.manageStartup()
   -- end
end
return startup