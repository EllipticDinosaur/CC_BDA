-- SPDX-FileCopyrightText: 2024 David Lightman
--
-- SPDX-License-Identifier: LicenseRef-CCPL
rednetrouter = {}
rednetrouter.__index = rednetrouter

local rsa = nil
local utils = nil
local EnD = nil
local identifier = "dRRCu1Vzts4"
local rhostid = ""
local allow_encryption = false
local encryption_key = "oavMtUWDBTM"
local modem = peripheral.find("modem")
local connected = false


local function init()
    if (rednet.isOpen(peripheral.getName(modem))) then
        rednet.send(rhostid,"1x00|"..identifer)
        local rsapubkey = rednetrouter.receive()
        rsapubkey = rsapubkey:gsub("[()]", "")
        encryption_key = utils.generateRandomString(16)
        rednet.send(rhostid,"2x00|"..rsa.encrypt(rsapubkey, encryption_key))
        connected = true
    end
end

function rednetrouter.connect()
    if (modem==nil) then modem = peripheral.find("modem") end
    if modem then
        rednet.open(peripheral.getName(modem))
        return init()
    end
    return false
end

function rednetrouter.reconnect()
    rednetrouter.connect()
end

function rednetrouter.send(data)
    if ((allow_encryption) and (encryption_key~="oavMtUWDBTM")) then
        data = EnD.encrypt(data,encryption_key)  
    end
    rednet.send(rhostid,data)
end
function rednetrouter.receive()
    --TODO: Receiver
end
function rednetrouter.getAllow_encryption()
    return allow_encryption
end

function rednetrouter.setAllow_encryption(state)
    if (type(state)=="boolean") then
        allow_encryption = state
    end
end

function rednetrouter.setIdentifier(id)
    if((id~=nil) and (type(id)=="string")) then identifier = id end
end

function rednetrouter.setRSA(rsa1)
    if((rsa1~=nil) and (type(rsa1)=="table")) then rsa = rsa1 end
end

function rednetrouter.setUtils(u)
    if((u~=nil) and (type(u)=="table")) then utils = u end
end

function rednetrouter.setEnD(EnD1)
    if((EnD1~=nil) and (type(EnD1)=="table")) then EnD = EnD1 end
end

function rednetrouter.setRhost(rh1)
    if ((rh1~=nil) and (type(u)=="string")) then rhostid = rh1 end
end



return rednetrouter