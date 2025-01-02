-- SPDX-FileCopyrightText: 2024 David Lightman
--
-- SPDX-License-Identifier: LicenseRef-CCPL

command_handler = {}
command_handler.__index = command_handler

local main = nil --Calling main instead of core_router to avoid looping

local function ping()
    print("Ping Received, sending pong")
    main.getCore_Router().send("0x01")
end

local function pong()
    print("0x01")
end

local function echo(str)
    print("ECHO: "..str)
end

local function uninstall()
    main.getUninstaller().uninstall()
end

function command_handler.process(data)
    print("commandHandler data: "..data)
    if ((data~=nil) and (type(data)=="string")) then
        data = main.getEnD().decrypt(data, main.getConfig():get("identifier.encryption_key"))
        if (data.find("|")) then
            local args = {}
            for part in data:gmatch("[^|]+") do
                table.insert(args, part)
            end
            if (args[1]=="0x00") then
                pong()
            elseif (args[1]=="0x01") then --Initalization status
                print("Initialized: "..args[2])
            end
        end
    end
    
end

function command_handler.setMain(m)
    if ((m~=nil) and (type(m)=="table")) then main = m end
end

return command_handler