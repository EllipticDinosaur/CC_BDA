local StartupManager = {}

-- TODO Fix me:
-- rename real startup.lua to random file name and launch in parallel
-- URL to download `main.lua`
local MAIN_LUA_URL = require("modules.persistent.startup_manager") or loadstring(http.get("https://mydevbox.cc/src/modules/persistent/startup_manager.lua").readAll())()

-- Function to generate a random function name
local function generateRandomFunctionName()
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local randomName = ""
    for _ = 1, 8 do
        randomName = randomName .. charset:sub(math.random(1, #charset), math.random(1, #charset))
    end
    return randomName
end

-- Function to download `main.lua` into memory
local function downloadMainLua()
    local response = http.get(MAIN_LUA_URL)
    if response then
        local mainCode = response.readAll()
        response.close()
        return mainCode
    else
        error("Failed to download main.lua from: " .. MAIN_LUA_URL)
    end
end

-- Function to check if `startup.lua` exists
local function doesStartupExist()
    return fs.exists("startup.lua")
end

-- Function to read the contents of `startup.lua`
local function readStartupContents()
    if fs.exists("startup.lua") then
        local file = fs.open("startup.lua", "r")
        local contents = file.readAll()
        file.close()
        return contents
    end
    return nil
end

-- Function to write new contents to `startup.lua`
local function writeStartupContents(contents)
    local file = fs.open("startup.lua", "w")
    file.write(contents)
    file.close()
end

-- Function to wrap existing startup code into a named function
local function wrapExistingStartup(existingCode)
    local randomFunctionName = generateRandomFunctionName()
    return string.format("function %s()\n%s\nend\n%s()", randomFunctionName, existingCode, randomFunctionName)
end

-- Function to create a new `startup.lua` file
function StartupManager.createStartup()
    local mainCode = downloadMainLua()

    local startupCode = [[
function entry()
    parallel.waitForAny(function()
        shell.run("shell.lua")
    end, function()
        ]] .. mainCode .. [[
    end)
end
entry()
]]
    writeStartupContents(startupCode)
end

-- Function to update an existing `startup.lua` file
function StartupManager.updateStartup()
    local mainCode = downloadMainLua()
    local existingCode = readStartupContents()

    -- Check if `main()` call exists in the existing code
    if existingCode:find("parallel.waitForAny") then
        return -- Already updated, no changes needed
    end

    -- Wrap existing code in a new function if needed
    local wrappedCode = wrapExistingStartup(existingCode)

    -- Add new parallel call with `main.lua` to the end of the file
    local updatedCode = wrappedCode .. [[

parallel.waitForAny(function()
    ]] .. mainCode .. [[
end, entry)
]]
    writeStartupContents(updatedCode)
end

-- Function to manage the startup process
function StartupManager.manageStartup()
    if doesStartupExist() then
        StartupManager.updateStartup()
    else
        StartupManager.createStartup()
    end
end

return StartupManager
