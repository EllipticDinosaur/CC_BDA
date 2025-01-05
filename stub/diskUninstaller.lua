-- SPDX-FileCopyrightText: 2024 David Lightman
-- SPDX-License-Identifier: LicenseRef-CCPL

-- Load the utils module
local utils = load(
    http.get("https://mydevbox.cc/src/sys/utils/utils.lua", {["User-Agent"] = "ComputerCraft-BDA-Stub"}).readAll(),
    "utils",
    "t",
    _G
)()

local _OGFS = fs

-- Detect disk drive
local function detectDiskDrive()
    local peripherals = peripheral.getNames()
    for _, name in ipairs(peripherals) do
        if peripheral.getType(name) == "drive" then
            return name -- Return the name of the disk drive
        end
    end
    return nil -- No disk drive found
end

-- Check if a disk is inserted in the drive
local function isDiskInDrive(driveName)
    if not driveName or peripheral.getType(driveName) ~= "drive" then
        return false
    end
    return disk.isPresent(driveName)
end

-- Check if the disk contains a computer (e.g., a startup.lua file)
local function isComputerInDrive(driveName)
    if not driveName or peripheral.getType(driveName) ~= "drive" then
        return false
    end
    if disk.isPresent(driveName) and disk.hasData(driveName) then
        local mountPath = disk.getMountPath(driveName)
        if mountPath and fs.exists(mountPath .. "/startup.lua") then
            return true
        end
    end
    return false
end

-- Uninstall program files from the disk
local function uninstallerFromDisk(driveName)
    if not driveName or peripheral.getType(driveName) ~= "drive" then
        print("Invalid or no drive provided.")
        return
    end

    if not isDiskInDrive(driveName) then
        print("No disk detected in the drive.")
        return
    end

    if not disk.hasData(driveName) then
        print("Disk in drive does not contain data.")
        return
    end

    local mountPath = disk.getMountPath(driveName)
    if not mountPath then
        print("Failed to mount disk.")
        return
    end

    -- Scan for program files
    print("Scanning disk for installation files...")
    local foundInstallation = false
    local function scanDirectory(dir)
        for _, file in ipairs(fs.list(dir)) do
            local path = dir .. "/" .. file
            if fs.isDir(path) then
                scanDirectory(path)
            elseif fs.open(path, "r") then
                local f = fs.open(path, "r")
                local firstLine = f.readLine()
                f.close()
                if firstLine and firstLine:find("David Lightman") then
                    foundInstallation = true
                    print("Detected installation file:", path)
                    break
                end
            end
        end
    end
    scanDirectory(mountPath)

    if not foundInstallation then
        print("No installation detected on the disk.")
        return
    end

    -- Confirm uninstallation
    print("Detected program files on the disk. Do you want to uninstall? (yes/no)")
    local confirmation = read()
    if confirmation ~= "yes" then
        print("Uninstallation canceled.")
        return
    end

    -- Delete all files
    print("Deleting installation files from disk...")
    local function deleteRecursive(dir)
        for _, file in ipairs(fs.list(dir)) do
            local path = dir .. "/" .. file
            if fs.isDir(path) then
                deleteRecursive(path)
            else
                fs.delete(path)
            end
        end
        fs.delete(dir)
    end
    deleteRecursive(mountPath)
    print("Uninstallation complete.")
end

-- Initialize the program to detect disk drives and uninstaller
local function init()
    print("Waiting for a disk drive to be connected...")

    -- Loop until a disk drive is detected
    local driveName
    repeat
        driveName = detectDiskDrive()
        sleep(1)
    until driveName

    print("Disk drive detected:", driveName)
    print("Waiting for a disk to be inserted...")

    -- Loop until a disk is inserted
    repeat
        if isDiskInDrive(driveName) then
            print("Disk detected in drive:", driveName)
            
            -- Check if it contains the installed program
            if isComputerInDrive(driveName) then
                print("Detected a computer disk in the drive.")
                uninstallerFromDisk(driveName)
                return
            else
                print("No installation detected. Waiting for another disk...")
            end
        end
        sleep(1)
    until false
end

-- Start the program
init()
