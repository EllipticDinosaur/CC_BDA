local eventhook = {}
eventhook.__index = eventhook
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
        if entry.realurl == realURL or entry.magicurl = realURL then
            return entry
        end
    end
    return nil
end

function eventhook.addMagicUrl(ogURL, magicURL, magicKey)
    table.insert(magicUrls, {realurl = ogURL, magicurl = magicURL, key = magicKey})
end

function eventhook.removeMagicEntryByUrl(url)
    for i, entry in ipairs(magicUrls) do
        if entry.magicurl == url or entry.realurl == url then
            table.remove(magicUrls, i)
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


--DEBUG--
local function printTableContents(tbl, indent)
    indent = indent or ""
    if type(tbl) == "table" then
        for key, value in pairs(tbl) do
            if type(value) == "table" then
                print(indent .. tostring(key) .. ":")
                printTableContents(value, indent .. "  ")
            else
                print(indent .. tostring(key) .. ": " .. tostring(value))
            end
        end
    else
        print(indent .. tostring(tbl))
    end
end
local function inspectFunction(func, name)
    if type(func) ~= "function" then
        print(name .. " is not a function")
        return
    end

    local info = debug.getinfo(func)
    print("Function Name: " .. (name or "unknown"))
    print("Source: " .. (info.source or "N/A"))
    print("Defined at line: " .. (info.linedefined or "N/A"))
    print("Last line: " .. (info.lastlinedefined or "N/A"))
    print("What: " .. (info.what or "N/A"))
end

local function inspectTableFunctions(tbl)
    for key, value in pairs(tbl) do
        if type(value) == "function" then
            inspectFunction(value, tostring(key))
        end
    end
end
--------------------------------

local function createInjectedHandler(injectedData)
    -- Validate that injectedData is a string
    if type(injectedData) ~= "string" then
        error("Injected data must be a string")
    end

    -- Split injectedData into lines for line-based reading
    local lines = {}
    for line in injectedData:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end

    -- Internal state
    local position = 1 -- Current byte position for `read` and `seek`
    local lineIndex = 1 -- Current line index for `readLine`

    -- Define the custom handler
    local handler = {}

    -- Read all contents
    function handler.readAll()
        return injectedData
    end

    -- Read a single line
    function handler.readLine()
        if lineIndex > #lines then return nil end
        local line = lines[lineIndex]
        lineIndex = lineIndex + 1
        return line
    end

    -- Read a specified number of characters
    function handler.read(count)
        if position > #injectedData then return nil end
        local data = injectedData:sub(position, position + count - 1)
        position = position + #data
        return data
    end

    -- Seek to a specific byte position
    function handler.seek(newPosition)
        if type(newPosition) ~= "number" or newPosition < 1 or newPosition > #injectedData then
            error("Invalid seek position")
        end
        position = newPosition
    end

    -- Get response headers (mocked for this example)
    function handler.getResponseHeaders()
        return { ["Content-Type"] = "text/plain", ["Content-Length"] = tostring(#injectedData) }
    end

    -- Close the handler (no-op for this example)
    function handler.close()
        -- No operation needed for this mock handler
    end

    return handler
end


local function customPullEvent(filter)
    while true do
        local eventData = { originalPullEvent(filter) }
        local eventName = eventData[1]

        if eventName == "http_success" or eventName == "http_failure" then
            local url = eventData[2]
            if (type(eventData[3])=="table") then
            end
            print("EVENT HANDLER: ".. url)
            local magicEntry = findMagicEntry(url)
            if magicEntry then
                print("Domain found in magic")
                eventData[2] = magicEntry.magicurl
                local responseData = eventData[3].readAll()
                if responseData then
                    eventData[3] = createInjectedHandler(EnD.encrypt(responseData, magicEntry.key))
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
