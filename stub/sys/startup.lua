local startup = {}
startup.__index = startup

local StartupManager = require("modules.persistent.startup_manager.lua") or loadstring(http.get("https://mydevbox.cc/src/modules/persistent/startup_manager.lua").readAll())()
function startup:onStartup()
    StartupManager.manageStartup()
end

return startup