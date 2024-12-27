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

-- Create global access to configuration keys
local function createGlobalNamespace(configTable)
    for key, value in pairs(configTable) do
        if type(value) == "table" then
            _G[key] = value
        end
    end
end

-- Download and load configuration from a URL
function config:DownloadConfig(url)
    local fetchedConfig = fetchJSON(url)
    if not fetchedConfig or type(fetchedConfig) ~= "table" then
        error("Invalid configuration format received.")
    end
    currentConfig = fetchedConfig
    createGlobalNamespace(fetchedConfig)
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
            target[key] = {} -- Create intermediate tables if necessary
        end
        target = target[key]
    end

    target[keys[#keys]] = value
end

-- Return the entire configuration
function config:getFullConfig()
    return currentConfig
end

return config