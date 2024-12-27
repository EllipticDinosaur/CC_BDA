local eventmanager = {}
eventmanager.__index = eventmanager

-- Generate a random name
local function generateRandomName()
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local name = ""
    for _ = 1, 12 do
        local index = math.random(1, #charset)
        name = name .. charset:sub(index, index)
    end
    return name
end

-- Event queue
local customEventQueue = {}

-- Define library
local customEvent = {}
randomQueueName = "A"..generateRandomName()
randomPullName = "A"..generateRandomName()

_G[randomQueueName] = function (eventName, ...)
    if type(eventName) ~= "string" then
        error("Event name must be a string.")
    end
    table.insert(customEventQueue, {eventName, {...}})
end

_G[randomPullName] = function(filter)
    while true do
        if #customEventQueue > 0 then
            local event = table.remove(customEventQueue, 1)
            local eventName, params = event[1], event[2]
            if not filter or eventName == filter then
                return eventName, table.unpack(params)
            else
                table.insert(customEventQueue, event)
            end
        end
        os.sleep(0.05)
    end
end
function eventmanager.getQueueEventName()
    return randomQueueName
end
function eventmanager.getPullEventName()
    return randomPullName
end
return eventmanager
