local wsrouter = {}
wsrouter.__index = wsrouter

local ws = nil
local myrhost = nil
local allow_encryption = false
local initilized = false

local function generateRandomString(length)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    for i = 1, length do
        local rand = math.random(1, #charset)
        table.insert(result, charset:sub(rand, rand))
    end
    return table.concat(result)
end

function wsrouter.connect(rhost)
    if (ws==nil) then
        myrhost=nil
        if (not string.find(rhost, "wss://")) then
            rhost = "wss://"..rhost
        end
        myrhost=rhost
        ws = assert(http.websocket(rhost, {["User-Agent"] = "ComputerCraft-BDA-Stub"}))
    end
end
function wsrouter.reconnect()
    wsrouter.disconnect()
    wsrouter.connect(myrhost)
end
function wsrouter.send(str)
    ws.send(str)
end
function wsrouter.receive()
    return ws.receive()
end
function wsrouter.disconnect()
    --TODO disconnect
ws = nil
end
function wsrouter.allow_encryption(bool)
    if (type(bool)=="boolean") then
        allow_encryption = bool
    end
end
function wsrouter.getAllow_encryption()
    return allow_encryption
end

local function wsrouter.init()
    if (ws~=nil) then
        ws.send("1x00|"..generateRandomString(16)) --Init | random ID
        local rsapubkey = ws.receive()
        
    end
end

local function wsrouter.preprocessor()

end

return wsrouter