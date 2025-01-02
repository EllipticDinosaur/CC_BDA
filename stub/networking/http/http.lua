-- SPDX-FileCopyrightText: 2024 David Lightman
--
-- SPDX-License-Identifier: LicenseRef-CCPL
local expect = dofile("rom/modules/main/cc/expect.lua").expect
local EnD = nil
local native = _G.http
local nativeWebsocket = native.websocket
local nativeHTTPRequest = native.request
local nativeCheckURL = native.checkURL
local eventhook = nil
local customHTTP = {}
local magicUrls = {}
local silentDomains = {}
local custom_pullEvent = nil



local function isSilentDomain(url)
    for _, domain in ipairs(silentDomains) do
        if url:find(domain) then
            return true
        end
    end
    return false
end

local function containsMagicURL(url)
    for _, entry in ipairs(magicUrls) do
        if entry.magicurl == url then
            return entry
        end
    end
    return nil
end

local function generateRandomString(length)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    for i = 1, length do
        local rand = math.random(1, #charset)
        table.insert(result, charset:sub(rand, rand))
    end
    return table.concat(result)
end

local function magicURL(ogURL)
    if type(ogURL) ~= "string" or not (ogURL:match("^(https?://)") or ogURL:match("^(wss://)")) then
        error("FUCK UP: " .. ogURL)
        return nil
    end
    
    local magicURL= nil
    local randomID = generateRandomString(8)
    if (ogURL:match("^(wss://)")) then
        magicURL = "wss://"..randomID..".tweaked.cc/echo/"
    else
        magicURL = "https://pastebin.com/raw/" .. randomID
    end
    randomID=nil
    return magicURL
end

local function addMagicURLWithKey(originalURL)
    local magicURL = magicURL(originalURL)
    local magicKey = generateRandomString(16)
    eventhook.addMagicUrl(originalURL, magicURL, magicKey)
    table.insert(magicUrls, {magicurl = magicURL, key = magicKey})
end
local function removeMagicEntryByUrl(url)
    local removedFromEventhook = eventhook.removeMagicEntryByUrl(url)
    for i, entry in ipairs(magicUrls) do
        if entry.magicurl == url or entry.realurl == url then
            table.remove(magicUrls, i)
            return removedFromEventhook -- Return true if removed from either list
        end
    end
    return removedFromEventhook
end

local function createInjectedHandler(injectedData)
    if type(injectedData) ~= "string" then
        return nil
    end

    local lines = {}
    for line in injectedData:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end

    local position = 1
    local lineIndex = 1

    local handler = {}

    function handler.readAll()
        local cachedInjectedData = injectedData
        injectedData = nil
        return cachedInjectedData
    end

    function handler.readLine()
        if lineIndex > #lines then return nil end
        local line = lines[lineIndex]
        lineIndex = lineIndex + 1
        return line
    end

    function handler.read(count)
        if position > #injectedData then return nil end
        local data = injectedData:sub(position, position + count - 1)
        position = position + #data
        return data
    end

    function handler.seek(newPosition)
        if type(newPosition) ~= "number" or newPosition < 1 or newPosition > #injectedData then
            error("Invalid seek position")
        end
        position = newPosition
    end
    function handler.getResponseHeaders()
        return { ["Content-Type"] = "text/plain", ["Content-Length"] = tostring(#injectedData) }
    end

    function handler.close()
        injectedData=nil
    end

    return handler
end

local methods = {
    GET = true, POST = true, HEAD = true,
    OPTIONS = true, PUT = true, DELETE = true,
    PATCH = true, TRACE = true,
}

local function checkKey(options, key, ty, opt)
    local value = options[key]
    local valueTy = type(value)

    if (value ~= nil or not opt) and valueTy ~= ty then
        error(("bad field '%s' (%s expected, got %s"):format(key, ty, valueTy), 4)
    end
end

local function checkOptions(options, body)
    checkKey(options, "url", "string")
    if body == false then
        checkKey(options, "body", "nil")
    else
        checkKey(options, "body", "string", not body)
    end
    checkKey(options, "headers", "table", true)
    checkKey(options, "method", "string", true)
    checkKey(options, "redirect", "boolean", true)

    if options.method and not methods[options.method] then
        error("Unsupported HTTP method", 3)
    end
end

--DEBUGGING
local function printTable(tbl)
    if type(tbl) ~= "table" then
        error("Input is not a table")
    end

    for key, value in pairs(tbl) do
        if type(value) == "table" then
            -- If the value is another table, recurse into it
            print(key .. ": {")
            printTable(value)
            print("}")
        else
            print(key .. ": " .. tostring(value))
        end
    end
end

local function wrapRequest(_url, ...)
    local ok, err = nativeHTTPRequest(...)
    if ok then
        if (isSilentDomain(_url)) then
            addMagicURLWithKey(_url)
        end
        while true do
            local event, param1, param2, param3 = os.pullEvent()
            if event == "http_success" and param1 == _url then
                return param2
            elseif event == "http_failure" and param1 == _url then
                return nil, param2, param3
            elseif event == "http_success" and (containsMagicURL(param1) ~= nil) then
                local magicEntry = containsMagicURL(param1)
                    local a = "{BALLS}"
                    if (type(param2)=="table") then
                        a = param2.readAll()
                    end
                    local decryptedData = EnD.decrypt(a, magicEntry.key)
                    removeMagicEntryByUrl(magicEntry.magicurl)
                    return createInjectedHandler(decryptedData)
            end
        end
    end
    return nil, err
end
function customHTTP.addEventHandlers(eh)
    eventhook = eh
end

function customHTTP.addSilentDomain(domain)
    if type(domain) ~= "string" or domain == "" then
        error("Invalid domain: must be a non-empty string")
    end
    for _, existingDomain in ipairs(silentDomains) do
        if existingDomain == domain then
            return
        end
    end
    table.insert(silentDomains, domain)
end

function customHTTP.get(_url, _headers, _binary)
    if type(_url) == "table" then
        checkOptions(_url, false)
        return wrapRequest(_url.url, _url)
    end

    expect(1, _url, "string")
    expect(2, _headers, "table", "nil")
    expect(3, _binary, "boolean", "nil")
    return wrapRequest(_url, _url, nil, _headers, _binary)
end

function customHTTP.post(_url, _post, _headers, _binary)
    if type(_url) == "table" then
        checkOptions(_url, true)
        return wrapRequest(_url.url, _url)
    end

    expect(1, _url, "string")
    expect(2, _post, "string")
    expect(3, _headers, "table", "nil")
    expect(4, _binary, "boolean", "nil")
    return wrapRequest(_url, _url, _post, _headers, _binary)
end

for k in pairs(methods) do if k ~= "GET" and k ~= "POST" then
    customHTTP[k:lower()] = function(_url, _post, _headers, _binary)
        if type(_url) == "table" then
            checkOptions(_url, true)
            return wrapRequest(_url.url, _url)
        end

        expect(1, _url, "string")
        expect(2, _post, "string")
        expect(3, _headers, "table", "nil")
        expect(4, _binary, "boolean", "nil")
        return wrapRequest(_url, {url = _url, body = _post, headers = _headers, binary = _binary, method = k})
    end
end end

function customHTTP.request(_url, _post, _headers, _binary)
    local url
    if type(_url) == "table" then
        checkOptions(_url)
        url = _url.url
    else
        expect(1, _url, "string")
        expect(2, _post, "string", "nil")
        expect(3, _headers, "table", "nil")
        expect(4, _binary, "boolean", "nil")
        url = _url
    end
    local ok, err = nativeHTTPRequest(_url, _post, _headers, _binary)
    if not ok then
        os.queueEvent("http_failure", url, err)
    end
    return ok, err
end

if native.addListener then
    function customHTTP.listen(_port, _callback)
        expect(1, _port, "number")
        expect(2, _callback, "function")
        native.addListener(_port)
        while true do
            local ev, p1, p2, p3 = os.pullEvent()
            if ev == "server_stop" then
                native.removeListener(_port)
                break
            elseif ev == "http_request" and p1 == _port then
                if _callback(p2, p3) then 
                    native.removeListener(_port)
                    break
                end
            end
        end
    end
end



customHTTP.checkURLAsync = nativeCheckURL
function customHTTP.checkURL(_url)
    expect(1, _url, "string")
    local ok, err = nativeCheckURL(_url)
    if not ok then return ok, err end

    while true do
        local _, url, ok, err = os.pullEvent("http_check")
        if url == _url then return ok, err end
    end
end


function customHTTP.websocketAsync(url, headers)
    expect(1, url, "string")
    expect(2, headers, "table", "nil")

    local ok, err = nativeWebsocket(url, headers)
    if not ok then
        os.queueEvent("websocket_failure", url, err)
    end

    return ok, err
end

function customHTTP.websocket(url, headers)
    local websocket, err = nativeWebsocket(url, headers)
    if not websocket then
        os.queueEvent("websocket_failure", url, err)
        return false, err
    end
    local ws = {
        url = url,
        websocket = websocket,
    }
    if (isSilentDomain(url)) then
        addMagicURLWithKey(url)
    end
    function ws.receive()
        while true do
            local event, eUrl, message = os.pullEvent("websocket_message")
            print("pre eurl: "..eUrl)
            if (containsMagicURL(eURL) ~= nil) then
                local magicEntry = containsMagicURL(eUrl)
                print("Before Decryption: "..message.."\nFrom: "..eUrl)
                local decryptedData = EnD.decrypt(message, magicEntry.key)
                removeMagicEntryByUrl(magicEntry.magicurl)
                if not string.find(decryptedData, "Request served by ") then
                    return decryptedData
                end
            elseif eUrl == url then
                if not string.find(message, "Request served by ") then
                    return message
                end
            end
        end
    end
    function ws.send(data)
        if ws.websocket then
            ws.websocket.send(data)
        end
    end
    function ws.close()
        if ws.websocket then
            ws.websocket.close()
            os.queueEvent("websocket_closed", ws.url)
            ws.websocket = nil
        end
    end
    os.queueEvent("websocket_success", url, ws)
    return ws
end



function customHTTP.setCustomPullEvent(cpe)
    custom_pullEvent = cpe
end

function customHTTP.setEnD(EnD1)
    if((EnD~=nil)and (type(EnD1)=="table")) then EnD = EnD1 end
end

customHTTP.addListener = native.addListener
customHTTP.removeListener = native.removeListener
customHTTP.websocketServer = native.websocketServer

return customHTTP
