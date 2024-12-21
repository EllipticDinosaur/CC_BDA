-- Generate a random name function
local function generateRandomName()
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local name = ""
    for _ = 1, 12 do -- Generate a 12-character random name
        local index = math.random(1, #charset)
        name = name .. charset:sub(index, index)
    end
    return name
end

-- Custom Event Library
local eventLibrary = {}

-- Internal event queue
local customEventQueue = {}

-- Queue an event
function eventLibrary.queueEvent(eventName, ...)
    table.insert(customEventQueue, {eventName, {...}})
end

-- Pull an event
function eventLibrary.pullEvent(filter)
    while true do
        -- Check the custom event queue
        if #customEventQueue > 0 then
            local event = table.remove(customEventQueue, 1)
            local eventName, params = event[1], event[2]
            if not filter or eventName == filter then
                return eventName, table.unpack(params)
            else
                -- Push it back if it doesn't match the filter
                table.insert(customEventQueue, event)
            end
        end
        -- Sleep to avoid busy-waiting
        os.sleep(0.05)
    end
end

-- Generate random names for the methods
local randomQueueName = "A"..generateRandomName()
local randomPullName = "A"..generateRandomName()

-- Add them to _G
_G[randomQueueName] = eventLibrary.queueEvent
_G[randomPullName] = eventLibrary.pullEvent

-- Return the names so they can be used
return {
    queueEventName = randomQueueName,
    pullEventName = randomPullName,
}
