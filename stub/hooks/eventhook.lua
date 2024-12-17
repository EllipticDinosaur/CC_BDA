local eventhook = {}
local originalPullEvent = _nil -- Backup the original pullEvent
local silentDomains = {} -- List of silent domains
local pendingHttpResults = {} -- Table to store pending HTTP results

-- Function to determine if a URL is silent
local function isSilentDomain(url)
    for _, domain in ipairs(silentDomains) do
        if url:find(domain) then
            return true
        end
    end
    return false
end

-- Function to add a silent domain
function eventhook.addSilentDomain(domain)
    table.insert(silentDomains, domain)
end

-- Function to remove a silent domain
function eventhook.removeSilentDomain(domain)
    for i, d in ipairs(silentDomains) do
        if d == domain then
            table.remove(silentDomains, i)
            break
        end
    end
end

-- Function to set the original pullEvent (for injection)
function eventhook.setOriginalPullEvent(ope)
    if type(ope) == "function" then
        originalPullEvent = ope
    else
        error("setOriginalPullEvent expects a function", 2)
    end
end

-- Custom pullEventRaw logic
local function customPullEventRaw(filter)
    while true do
        local eventData = { originalPullEvent(filter) }
        local eventName = eventData[1]

        -- Check for http_success or http_failure
        if eventName == "http_success" or eventName == "http_failure" then
            local url = eventData[2]

            -- If the domain is silent, bypass custom logic and call original pullEvent
            if isSilentDomain(url) then
                return originalPullEvent(filter) -- Fire event through original pullEvent
            else
                -- For non-silent domains, handle as usual (custom logic)
                if eventName == "http_success" then
                    pendingHttpResults[url] = { true, table.unpack(eventData, 3) }
                elseif eventName == "http_failure" then
                    pendingHttpResults[url] = { false, table.unpack(eventData, 3) }
                end

                -- Return the event data
                return table.unpack(eventData)
            end
        else
            -- Handle other events as usual
            return table.unpack(eventData)
        end
    end
end

-- Override http.get to handle silent domains
local nativeHttpGet = _G.http.get

function _G.http.get(url, headers, binary)
    -- If the URL is silent, bypass the custom pullEvent and fetch the response
    if isSilentDomain(url) then
        -- Send the HTTP request
        local response = nativeHttpGet(url, headers, binary)

        -- Wait for the original event
        while true do
            local event, param1, param2 = originalPullEvent()
            if event == "http_success" and param1 == url then
                return param2 -- Return the response object
            elseif event == "http_failure" and param1 == url then
                return nil, param2 -- Return failure
            end
        end
    else
        -- Use the normal http.get for non-silent domains
        return nativeHttpGet(url, headers, binary)
    end
end

-- Function to activate the custom pullEvent
function eventhook.activate()
    _G.os.pullEventRaw = customPullEventRaw
    _G.os.pullEvent = customPullEventRaw
end

-- Function to deactivate and restore the original pullEvent
function eventhook.deactivate()
    _G.os.pullEventRaw = originalPullEvent
    _G.os.pullEvent = originalPullEvent
end

return eventhook
