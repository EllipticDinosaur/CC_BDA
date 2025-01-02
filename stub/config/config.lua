local config = {}
config.__index = config

-- In-memory storage for configuration
local currentConfig = nil

-- Fetch JSON from a URL
local function fetchJSON(url)
    if not http then
        error("HTTP API is not enabled!")
    end
    local response = http.get(url)
    if not response then
        error("Failed to fetch configuration from " .. url)
    end
    local content = response.readAll()
    response.close()
    return textutils.unserializeJSON(content)
end

-- Download and load configuration from a URL
function config:DownloadConfig(url)
    local fetchedConfig = fetchJSON(url)
    if not fetchedConfig or type(fetchedConfig) ~= "table" then
        error("Invalid configuration format received.")
    end
    currentConfig = fetchedConfig
    print("Downloaded config")
    return fetchedConfig
end

-- Reload configuration
function config:reloadConfig(url)
    return self:DownloadConfig(url)
end

-- Retrieve a specific value by its path
function config:get(path)
    if not currentConfig then
        error("Configuration is not loaded.")
    end

    local keys = {}
    for key in string.gmatch(path, "[^.]+") do
        table.insert(keys, key)
    end

    local value = currentConfig
    for _, key in ipairs(keys) do
        if type(value) ~= "table" or value[key] == nil then
            return nil -- Return nil if any part of the path does not exist
        end
        value = value[key]
    end
    return value
end

-- Set a specific value by its path
function config:set(path, value)
    if not currentConfig then
        error("Configuration is not loaded.")
    end

    local keys = {}
    for key in string.gmatch(path, "[^.]+") do
        table.insert(keys, key)
    end

    local target = currentConfig
    for i = 1, #keys - 1 do
        local key = keys[i]
        if type(target[key]) ~= "table" then
            -- If the key does not exist or is not a table, create an empty table
            target[key] = {}
        end
        target = target[key]
    end

    local finalKey = keys[#keys]

    target[finalKey] = value
end

-- Return the entire configuration
function config:getFullConfig()
    return currentConfig
end

-- Initialize the configuration into a local table
function config:initialize()
    if not currentConfig then
        error("Configuration is not loaded.")
    end

    -- Create a local namespace for configuration keys
    local namespace = {}
    for key, value in pairs(currentConfig) do
        if type(value) == "table" then
            namespace[key] = value
        end
    end

    return namespace
end

return config
