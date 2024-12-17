local expect = dofile("rom/modules/main/cc/expect.lua").expect

local native = http
local nativeHTTPRequest = native.request

-- Silent domain list
local silentDomains = {}
local pendingSilentResults = {}

-- HTTP methods supported
local methods = {
    GET = true, POST = true, HEAD = true,
    OPTIONS = true, PUT = true, DELETE = true,
    PATCH = true, TRACE = true,
}

-- Check if URL matches a silent domain
local function isSilentDomain(url)
    for _, domain in ipairs(silentDomains) do
        if url:find(domain) then
            return true
        end
    end
    return false
end

-- Register a domain as silent
function addSilentDomain(domain)
    table.insert(silentDomains, domain)
end

-- Utility to validate options
local function checkKey(options, key, ty, opt)
    local value = options[key]
    local valueTy = type(value)

    if (value ~= nil or not opt) and valueTy ~= ty then
        error(("bad field '%s' (%s expected, got %s)"):format(key, ty, valueTy), 4)
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

-- Internal HTTP request wrapper for silent domains
local function wrapRequest(url, ...)
    local ok, err = nativeHTTPRequest(...)
    if not ok then return nil, err end

    if isSilentDomain(url) then
        -- Silent domain: intercept event internally
        while true do
            local event, param1, param2, param3 = os.pullEventRaw()
            if event == "http_success" and param1 == url then
                pendingSilentResults[url] = param2
                return param2
            elseif event == "http_failure" and param1 == url then
                pendingSilentResults[url] = nil
                return nil, param2, param3
            end
        end
    else
        -- Non-silent domain: behave normally
        while true do
            local event, param1, param2, param3 = os.pullEvent()
            if event == "http_success" and param1 == url then
                return param2
            elseif event == "http_failure" and param1 == url then
                return nil, param2, param3
            end
        end
    end
end

-- Overridden HTTP GET function
function get(_url, _headers, _binary)
    if type(_url) == "table" then
        checkOptions(_url, false)
        return wrapRequest(_url.url, _url)
    end

    expect(1, _url, "string")
    expect(2, _headers, "table", "nil")
    expect(3, _binary, "boolean", "nil")
    return wrapRequest(_url, _url, nil, _headers, _binary)
end

-- Overridden HTTP POST function
function post(_url, _post, _headers, _binary)
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

-- Support other HTTP methods
for k in pairs(methods) do
    if k ~= "GET" and k ~= "POST" then
        _ENV[k:lower()] = function(_url, _post, _headers, _binary)
            if type(_url) == "table" then
                checkOptions(_url, true)
                return wrapRequest(_url.url, _url)
            end

            expect(1, _url, "string")
            expect(2, _post, "string")
            expect(3, _headers, "table", "nil")
            expect(4, _binary, "boolean", "nil")
            return wrapRequest(_url, { url = _url, body = _post, headers = _headers, binary = _binary, method = k })
        end
    end
end

-- Add silent domain functionality to global API
http = {
    get = get,
    post = post,
    request = native.request, -- Optional for async support
    addSilentDomain = addSilentDomain,
}
return http