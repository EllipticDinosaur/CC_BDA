-- SPDX-FileCopyrightText: 2024 David Lightman
--
-- SPDX-License-Identifier: LicenseRef-CCPL
core_router = {}
core_router.__index = core_router

local modem = peripheral.find("modem")
local protocol = -1
local wsrouter = nil
local rednetrouter = nil
local command_handler = nil
local rednetEnabled = false
local wsEnabled = false

local function detectProtocol()
    if (rednetEnabled and (peripheral.find("modem")~=nil)) then
        protocol = 0
    elseif (wsEnabled) then
        protocol = 1
    else
        protocol = -1
    end
end

local function master_receiver(protocol)
    if protocol == 0 then
        return rednetrouter.receive()
    elseif protocol == 1 then
        return wsrouter.receive()
    end
end
local function master_send2host(protocol, data)
    if protocol == -1 then detectProtocol() end
    if protocol==0 then
        --rednet
        if (rednetrouter~=nil) then
            if (rednetrouter.isClosed()) then rednetrouter.reconnect() end
            rednetrouter.send(data)
        end
    elseif protocol==1 then
        if (wsrouter~=nil) then
            if (wsrouter.isClosed()) then wsrouter.reconnect() end
            wsrouter.send(data)
            core_router.receive4host()
        end
    end
end

function core_router.TXRX2Host(data, isencrypted)
    if (wsrouter==nil) then
        print("wsrouter is null")
    else
        if (wsrouter.isClosed()) then wsrouter.reconnect() end
        command_handler.process(wsrouter.sendreceive(data, isencrypted))
    end
end

function core_router.send2host(data)
    if (data~=nil or data ~= "") then master_send2host(protocol, data) end
end

function core_router.receive4host()
    command_handler.process(master_receiver(protocol))
end

function core_router.setWsrouter(ws)
    if ((ws~=nil) and (type(ws)=="table")) then wsrouter = ws end
end

function core_router.setRednetrouter(rr)
    if ((rr~=nil) and (type(rr)=="table")) then rednetrouter = rr end
end

function core_router.setRednetEnabled(state)
    if ((state~=nil) and (type(state)=="boolean")) then rednetEnabled = state end
end

function core_router.setWsEnabled(state)
    if ((state~=nil) and (type(state)=="boolean")) then wsEnabled = state end
end

function core_router.setCommandHandler(ch)
    if ((ch~=nil) and (type(ch)=="table")) then command_handler = ch end
end

return core_router