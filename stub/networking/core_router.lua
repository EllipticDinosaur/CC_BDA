core_router = {}
core_router.__index = core_router

local modem = peripheral.find("modem")
local main = nil
local protocol = -1

function core_router.setMain(m)
    if (main==nil) then
        main = m
    end
end

local function detectProtocol()
    if (main~=nil) then
        main.getConfig().get("")
    end
end

local function master_receiver(protocol)

end
local function master_send2host(protocol, host, data)
    if protocol==0 then
        --rednet
        if(modem) then
            if (rednet.isOpen()) then
                rednet.send()
            else
                
            end
        end
    elseif protocol==1 then

    end
end


function core_router.send2host(data)

end

function core_router.receive4host()

end
return core_router