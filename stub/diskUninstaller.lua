-- SPDX-FileCopyrightText: 2024 David Lightman
-- SPDX-License-Identifier: LicenseRef-CCPL
--
-- Spook behind the bar, unmarked car --

local utils = load(http.get("https://mydevbox.cc/src/sys/utils/utils.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(), "utils", "t", _G)()
local _OGFS = fs

-- Helper Functions
local function detectDiskDrive()
    -- Get a list of all peripherals
    local peripherals = peripheral.getNames()
    for _, name in ipairs(peripherals) do
        if peripheral.getType(name) == "drive" then
            return name -- Return the name of the disk drive
        end
    end
    return nil -- No disk drive found
end

local function isDiskInDrive(driveName)
    if not driveName or peripheral.getType(driveName) ~= "drive" then
        return false -- Invalid or no drive provided
    end
    return disk.isPresent(driveName) -- Check if a disk is present in the drive
end

local function scanForBackDoorAdmin(driveName)
    if not driveName or peripheral.getType(driveName) ~= "drive" then
        return nil -- Invalid or no drive provided
    end
    if disk.isPresent(driveName) and disk.hasData(driveName) then
        local mountPath = disk.getMountPath(driveName)
        for _, file in ipairs(fs.list(mountPath)) do
            local filePath = mountPath .. "/" .. file
            if not fs.isDir(filePath) then
                local f = fs.open(filePath, "r")
                if f then
                    local line = f.readLine()
                    f.close()
                    if line and line:find("David Lightman") then
                        return filePath -- Found the BackDoorAdmin file
                    end
                end
            end
        end
    end
    return nil -- BackDoorAdmin file not found
end

-- Function to Restore Original `startup.lua`
local function restoreStartup(driveName)
    local mountPath = disk.getMountPath(driveName)
    if not mountPath then
        print("Failed to mount disk.")
        return false
    end

    -- Helper to extract boot file from startup.lua
    local function getBootFile()
        local startupPath = mountPath .. "/startup.lua"
        if not fs.exists(startupPath) then
            return nil
        end

        local f = fs.open(startupPath, "r")
        if not f then
            return nil
        end

        for line in f.readLine do
            local bootfile = string.match(line, '^%s*shell%.run%(%s*["\'](.-)["\']%s*%)')
            if bootfile then
                f.close()
                return bootfile
            end
        end

        f.close()
        return nil
    end

    -- Extract backup location from boot file
    local function getStartupBackup(bootfile)
        if not bootfile or not fs.exists(mountPath .. "/" .. bootfile) then
            return nil
        end

        local f = fs.open(mountPath .. "/" .. bootfile, "r")
        if not f then
            return nil
        end

        for line in f.readLine do
            local backupPath = string.match(line, "^%-%-(%S+)%.$")
            if backupPath then
                f.close()
                return backupPath
            end
        end

        f.close()
        return nil
    end

    -- Step 1: Locate boot file from startup.lua
    local bootfile = getBootFile()
    if not bootfile then
        print("Boot file not found in startup.lua.")
        return false
    end

    print("Boot file located: " .. bootfile)

    -- Step 2: Locate startup backup from boot file
    local startupBackup = getStartupBackup(bootfile)
    if startupBackup then
        print("Startup backup located: " .. startupBackup)
        if fs.exists(mountPath .. "/" .. startupBackup) then
            -- Restore the backup
            fs.delete(mountPath .. "/startup.lua")
            fs.move(mountPath .. "/" .. startupBackup, mountPath .. "/startup.lua")
            print("Restored original startup.lua from backup.")
            return true
        else
            print("Startup backup file does not exist.")
        end
    else
        print("No startup backup found in the boot file.")
    end

    return false
end

-- Uninstaller Function
local function uninstaller(driveName)
    if not driveName or peripheral.getType(driveName) ~= "drive" then
        print("Invalid disk drive.")
        return
    end

    if not isDiskInDrive(driveName) then
        print("No disk in drive.")
        return
    end

    -- Attempt to restore original startup.lua
    if not restoreStartup(driveName) then
        print("Failed to restore original startup.lua.")
    end

    -- Scan for the BackDoorAdmin
    local BackDoorAdminFile = scanForBackDoorAdmin(driveName)
    if not BackDoorAdminFile then
        print("BackDoorAdmin not found on the disk.")
        return
    end

    print("Uninstaller detected the BackDoorAdmin at: " .. BackDoorAdminFile)
    print("Do you want to uninstall? (yes/no)")

    local confirmation = read()
    if confirmation ~= "yes" then
        print("Uninstallation canceled.")
        return
    end

    -- Delete the BackDoorAdmin files
    local function deleteRecursive(dir)
        if fs.exists(dir) then
            if fs.isDir(dir) then
                for _, file in ipairs(fs.list(dir)) do
                    deleteRecursive(dir .. "/" .. file)
                end
            end
            fs.delete(dir)
        end
    end

    local installDir = fs.getDir(BackDoorAdminFile)
    deleteRecursive(installDir)
    print("Deleted BackDoorAdmin directory: " .. installDir)

    print("Uninstallation complete.")
end

-- Main Initialization Function
local function init()
    print("Waiting for a disk drive to be connected...")
    local driveName

    -- Loop until a disk drive is detected
    while true do
        driveName = detectDiskDrive()
        if driveName then
            print("Disk drive detected: " .. driveName)
            break
        end
        sleep(1)
    end

    print("Waiting for a disk to be inserted...")
    while not isDiskInDrive(driveName) do
        sleep(1) -- Wait for a disk to be inserted
    end

    print("Disk inserted. Checking for BackDoorAdmin...")
    local BackDoorAdminFile = scanForBackDoorAdmin(driveName)
    if BackDoorAdminFile then
        print("BackDoorAdmin detected on disk.")
        print("Do you want to uninstall BackDoorAdmin? (yes/no)")
        local confirmation = read()
        if confirmation == "yes" then
            uninstaller(driveName)
        else
            print("BackDoorAdmin left intact.")
        end
    else
        print("No BackDoorAdmin detected on the disk.")
    end
end

-- Start the BackDoorAdmin
init()
