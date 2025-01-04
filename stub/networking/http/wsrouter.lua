-- SPDX-FileCopyrightText: 2024 David Lightman
--
-- SPDX-License-Identifier: LicenseRef-CCPL
local wsrouter = {}
wsrouter.__index = wsrouter

local identifier = "dRRCu1Vzts4"
local encryption_key = "oavMtUWDBTM"
local OwnerID = "ZLWiebvQ_Ss"
local rsa = nil
local ws = nil
local utils = nil
local EnD = nil
local config = nil
local myrhost = ""
local allow_encryption = false
local initilized = false
local connected = false

local function init()
    if (ws~=nil and OwnerID~="ZLWiebvQ_Ss") then
        ws.send("1x00|"..identifier) --Init | random ID
        local rsapubkey = ws.receive()
        rsapubkey = rsapubkey:gsub("[()]", "")
        encryption_key = utils.generateRandomString(16)
        config:set("identifier.encryption_key",encryption_key)
        print("set Encryption key: "..config:get("identifier.encryption_key"))
        local publicKeyE, publicKeyN = rsapubkey:match("(%d+),%s*(%d+)")
        publicKeyE, publicKeyN = tonumber(publicKeyE), tonumber(publicKeyN)
        wsrouter.sendreceive(("1x01|"..identifier.."|"..OwnerID.."|"..rsa.encrypt(publicKeyE, publicKeyN, "2x01|"..encryption_key)), false)
        return true
    end
    return false
end
function wsrouter.connect(rhost)
    if (ws==nil) then
        local myrhost=nil
        if (not string.find(rhost,"wss://")) then
            myrhost = "wss://"..rhost
        else
            myrhost=rhost
        end
        ws = assert(http.websocket(myrhost, {["User-Agent"] = "ComputerCraft-BDA-Stub"}))
        connected=true
        return init()
    end
    return false
end
function wsrouter.reconnect()
    wsrouter.disconnect()
    return wsrouter.connect(myrhost)
end
function wsrouter.send(str)
    if ((allow_encryption) and (encryption_key~="oavMtUWDBTM")) then
        str = EnD.encrypt(str,encryption_key)
    end
    local ok,err= ws.send(str)
    if (ok==nil) then connected=false else connected = true end
    return ok, err
end

function wsrouter.sendreceive(str, isEncrypted)
    if (isEncrypted) then
        if ((allow_encryption) and (encryption_key~="oavMtUWDBTM")) then
            str = EnD.encrypt(str,encryption_key)
        end
    end
    local ok, err= ws.send(str)
    if (ok==nil or ok == false) then connected=false else connected = true end
    if ok then
        return ws.receive()
    end
    return nil
end

function wsrouter.receive()
    tries = 0
    ::retry::
    if tries > 3 then return "{failed to receive within 3 tries}" end
    if (ws~=nil) then
        local message, err = ws.receive()
        if (err) then connected = false
        else connected = true end
        return message
    else
       -- wsrouter.reconnect()
       print("failed to receive packet")
        tries = tries + 1
        goto retry
    end
    return "{ws was nil}"
end
function wsrouter.disconnect()
    if (ws~=nil) then 
        ws.close()
    end
    connected = false
    ws = nil
end
function wsrouter.isClosed()
    return not connected
end
function wsrouter.allow_encryption(bool)
    if (type(bool)=="boolean") then
        allow_encryption = bool
    end
end
function wsrouter.getAllow_encryption()
    return allow_encryption
end

function wsrouter.setIdentifier(id)
    if((id~=nil) and (type(id)=="string")) then 
        identifier = id
    end
end

function wsrouter.setRSA(rsa1)
    if((rsa1~=nil) and (type(rsa1)=="table")) then rsa = rsa1 end
end
function wsrouter.setUtils(u)
    if((u~=nil) and (type(u)=="table")) then utils = u end
end

function wsrouter.setEnD(EnD1)
    if((EnD1~=nil) and (type(EnD1)=="table")) then EnD = EnD1 end
end

function wsrouter.setConfig(cfg)
    if((cfg~=nil) and (type(cfg)=="table")) then config = cfg end
end

function wsrouter.setRawRhost(rhost1)
    if((myrhost~=nil) and (type(myrhost)=="string")) then myrhost = rhost1 end
end

function wsrouter.setOwnerID(id)
    if((id~=nil) and (type(id)=="string")) then OwnerID = id end
end

return wsrouter