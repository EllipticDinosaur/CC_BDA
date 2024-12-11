core_router = {}
core_router.__index = core_router

local modem = peripheral.find("modem")

function send2host(protocol, host, data)
    if protocol==0 then
        --rednet
        if(modem) then
            if (rednet.isOpen()) then
                rednet.send()
            else
                
            end
        end
    end
end

return core_router