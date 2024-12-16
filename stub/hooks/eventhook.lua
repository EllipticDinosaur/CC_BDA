local eventhook = {}

-- Backup the original pullEventRaw and http functions
local originalPullEvent = _G.os.pullEventRaw
local originalHttpRequest = _G.http.request
local originalHttpGet = _G.http.get
local originalHttpPost = _G.http.post

-- Hidden events, silent domains, and blacklisted URLs
local hiddenEvents = {}
local silentDomains = {}
local blacklistedUrls = {}

-- Event queue for custom events
local eventQueue = {}

-- External event handler module
local eventHandler = nil

-- **Event Management**
function eventhook.hideEvent(eventName)
    hiddenEvents[eventName] = true
end

function eventhook.showEvent(eventName)
    hiddenEvents[eventName] = nil
end

local function isEventHidden(eventName)
    return hiddenEvents[eventName] or false
end

-- **Silent Domain Management**
function eventhook.addSilentDomain(domain)
    table.insert(silentDomains, domain)
end

function eventhook.removeSilentDomain(domain)
    for i, d in ipairs(silentDomains) do
        if d == domain then
            table.remove(silentDomains, i)
            break
        end
    end
end

local function isSilentDomain(url)
    for _, domain in ipairs(silentDomains) do
        if url:find(domain) then
            return true
        end
    end
    return false
end

-- **Blacklist Management**
function eventhook.addBlacklistedUrl(url)
    table.insert(blacklistedUrls, url)
end

function eventhook.removeBlacklistedUrl(url)
    for i, u in ipairs(blacklistedUrls) do
        if u == url then
            table.remove(blacklistedUrls, i)
            break
        end
    end
end

local function isUrlBlacklisted(url)
    for _, blockedUrl in ipairs(blacklistedUrls) do
        if url:find(blockedUrl) then
            return true
        end
    end
    return false
end

-- **Event Handling**
function eventhook.setEventHandler(handler)
    eventHandler = handler
end

-- Custom pullEventRaw
local function PullEventRaw(filter)
    -- Process queued events first
    if #eventQueue > 0 then
        local queuedEvent = table.remove(eventQueue, 1)
        if not filter or queuedEvent[1] == filter then
            return table.unpack(queuedEvent)
        end
    end

    -- Pull the next event
    local eventData = { originalPullEvent(filter) }
    local eventName = eventData[1]

    -- Handle HTTP events
    if eventName == "http_success" or eventName == "http_failure" then
        local url = eventData[2]
        if isSilentDomain(url) then
            -- Process silently through the event handler
            if eventHandler then
                local result = eventHandler:handle(eventName, table.unpack(eventData, 2))
                -- If the handler returns a result, enqueue it for delivery
                if result then
                    eventhook.createEvent(eventName, table.unpack(result))
                end
            end
            -- Prevent the real event from being raised
            return nil
        else
            return table.unpack(eventData)
        end
    end

    -- For other events, pass them through as usual
    return table.unpack(eventData)
end


-- Custom HTTP wrappers
local function customHttpRequest(url, ...)
    if isUrlBlacklisted(url) then
        --error("HTTP request to blacklisted URL: " .. url, 2)
    end
    originalHttpRequest(url, ...)
end

local function customHttpGet(url, ...)
    if isUrlBlacklisted(url) then
        --error("HTTP GET request to blacklisted URL: " .. url, 2)
    end
    return originalHttpGet(url, ...)
end

local function customHttpPost(url, data, headers, ...)
    if isUrlBlacklisted(url) then
       -- error("HTTP POST request to blacklisted URL: " .. url, 2)
    end
    return originalHttpPost(url, data, headers, ...)
end

-- Replace os.pullEventRaw and HTTP functions
function eventhook.activate()
    _G.os.pullEventRaw = PullEventRaw
    _G.os.pullEvent = PullEventRaw
    _G.http.request = customHttpRequest
    _G.http.get = customHttpGet
    _G.http.post = customHttpPost
end

function eventhook.deactivate()
    _G.os.pullEventRaw = originalPullEvent
    _G.http.request = originalHttpRequest
    _G.http.get = originalHttpGet
    _G.http.post = originalHttpPost
end

function eventhook.getOriginalPullEvent()
    return originalPullEvent
end

-- **Custom Event Queue**
function eventhook.createEvent(eventName, ...)
    table.insert(eventQueue, { eventName, ... })
end

-- Return the API
return eventhook
