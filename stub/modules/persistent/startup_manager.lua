-- Function to generate a random filename
local function generateRandomFilename()
    local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
    local name = ""
    for i = 1, 8 do
        name = name .. chars:sub(math.random(1, #chars), math.random(1, #chars))
    end
    return name .. ".lua"
end

-- Function to check if `startup.lua` contains parallel logic for the target function
local function startupContainsParallel(targetFunction)
    if not fs.exists("startup.lua") then
        return false
    end
    local file = fs.open("startup.lua", "r")
    local content = file.readAll()
    file.close()
    return content:find("parallel") and content:find(targetFunction)
end

-- Main task: rename startup and create a new one
local function setupStartup(targetFunction)
    if startupContainsParallel(targetFunction) then
        print("startup.lua already contains the required parallel setup. Exiting.")
        return
    end

    local newName = nil

    -- Step 1: Rename existing startup.lua to a random file
    if fs.exists("startup.lua") then
        newName = generateRandomFilename()
        fs.move("startup.lua", newName)
        fs.setRenamedStartup(newName) -- Register the renamed startup with HiddenFS
        print("Renamed existing startup.lua to " .. newName)
    end

    -- Step 2: Create a new startup.lua with parallel logic
    local file = fs.open("startup.lua", "w")
    file.write([[

local function targetFunction()
    ]] .. targetFunction .. [[
end

local function originalStartup()
    if fs.exists("]] .. (newName or "") .. [[") then
        shell.run("]] .. (newName or "") .. [[")
    end
end

parallel.waitForAny(targetFunction, originalStartup)
]])
    file.close()
    print("Created new startup.lua with parallel execution.")
end

-- Call the function with your desired target function logic
setupStartup([[

    print("Running target function!")
    while true do
        sleep(1) -- Simulate long-running task
    end
]])
