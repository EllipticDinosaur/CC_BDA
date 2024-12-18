local eventhook = {}
local EnD = (pcall(require, "sys.crypto.EnD") and require("sys.crypto.EnD")) or load(http.get("https://mydevbox.cc/src/sys/crypto/EnD.lua", {["User-Agent"] = "ComputerCraft-BDA-Client"}).readAll(), "EnD", "t", _G)()
local originalPullEvent = _nil
local originalPullEventRaw = _nil
local magicUrls = {} -- realURL, magicURL, magicKey

function eventhook.getMagicURLs()
    return magicUrls
end
-- Function to determine if a URL is silent
local function findMagicEntry(realURL)
    for _, entry in ipairs(magicUrls) do
        if entry.realurl == realURL then
            return entry
        end
    end
    return nil
end

function eventhook.addMagicUrl(ogURL, magicURL, magicKey)
    table.insert(magicUrls, {realurl = ogURL, magicurl = magicURL, key = magicKey})
end

function eventhook.removeMagicEntryByUrl(url)
    for i, entry in ipairs(eventhook.magicUrls) do
        if entry.magicurl == url or entry.realurl == url then
            table.remove(eventhook.magicUrls, i)
            return true
        end
    end
    return false
end

function eventhook.setOriginalPullEvent(ope)
    --if type(ope) == "function" then
        originalPullEvent = ope
   -- else
   --     error("setOriginalPullEvent expects a function", 2)
  --  end
end

function eventhook.setOriginalPullEventRaw(oper)
   --if type(ope) == "function" then
        originalPullEventRaw = oper
   -- else
     --   error("setOriginalPullEvent expects a function", 2)
    --end
end

local function customPullEvent(filter)
    while true do
        local eventData = { originalPullEvent(filter) }
        local eventName = eventData[1]

        if eventName == "http_success" or eventName == "http_failure" then
            local url = eventData[2]
            local magicEntry = findMagicEntry(url)
            if magicEntry then
                print("Domain found in magic")
                eventData[2] = magicEntry.magicurl
                local responseData = eventData[3]
                if responseData then
                    eventData[3] = EnD.encrypt(responseData, magicEntry.key)
                end
            end
            return table.unpack(eventData)
        else
            return table.unpack(eventData)
        end
    end
end




local function customPullEventRaw(sFilter)
    while true do
        local eventData = table.pack(originalPullEventRaw(sFilter))
        local eventName = eventData[1]

        if eventName == "http_success" or eventName == "http_failure" then
            local url = eventData[2]
            local magicEntry = findMagicEntry(url)
            if magicEntry then
                eventData[2] = magicEntry.magicurl
                local responseData = eventData[3]
                if responseData then
                    eventData[3] = EnD.encrypt(responseData, magicEntry.magicKey)
                end
            end
            
            return table.unpack(eventData, 1, eventData.n)
        else
            return table.unpack(eventData, 1, eventData.n)
        end
    end
end

-- Function to activate the custom pullEvent
function eventhook.activate()
    _G.os.pullEventRaw = customPullEventRaw
    _G.os.pullEvent = customPullEvent
end

-- Function to deactivate and restore the original pullEvent
function eventhook.deactivate()
    _G.os.pullEventRaw = originalPullEventRaw
    _G.os.pullEvent = originalPullEvent
end

return eventhook
