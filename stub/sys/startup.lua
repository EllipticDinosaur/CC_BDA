local startup = {}
startup.__index = startup

local StartupManager = require("modules.persistent.startup_manager")
function startup:onStartup()
    StartupManager.manageStartup()
end

return startup