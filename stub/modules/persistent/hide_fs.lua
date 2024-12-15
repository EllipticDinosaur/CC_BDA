local HiddenFS = {}
local hiddenDirs = {}
local renamedStartupFile = nil -- To store the renamed startup file name

-- Backup the original fs
local originalFS = fs -- Fix: Ensure originalFS is correctly initialized here

-- Add a directory to the hidden list
function HiddenFS.hide(dir)
    hiddenDirs[dir] = true
end

-- Remove a directory from the hidden list
function HiddenFS.unhide(dir)
    hiddenDirs[dir] = nil
end

-- Check if a directory is hidden
function HiddenFS.isHidden(dir)
    return hiddenDirs[dir] or false
end

-- Function to set the renamed startup file
function HiddenFS.setRenamedStartup(fileName)
    renamedStartupFile = fileName
end

-- Enable the custom fs API globally
function HiddenFS.enable()
    _G.fs = HiddenFS
    _ENV.fs = HiddenFS
end

-- Disable the custom fs API and restore the original
function HiddenFS.disable()
    _G.fs = originalFS -- Fix: Correct reference to the original filesystem
    _ENV.fs = originalFS
end

-- Override the list method
function HiddenFS.list(path, showHidden)
    local items = originalFS.list(path)
    local filteredItems = {}
    for _, item in ipairs(items) do
        if showHidden or not hiddenDirs[item] then
            table.insert(filteredItems, item)
        end
    end
    return filteredItems
end

-- Override the exists method
function HiddenFS.exists(path)
    if path == "startup.lua" then
        if renamedStartupFile then
            return originalFS.exists(renamedStartupFile)
        end
        return false
    end
    for hidden in pairs(hiddenDirs) do
        if path == hidden or string.sub(path, 1, #hidden + 1) == hidden .. "/" then
            return false
        end
    end
    return originalFS.exists(path)
end

-- Override the delete method
function HiddenFS.delete(path)
    if path == "startup.lua" then
        if renamedStartupFile then
            originalFS.delete(renamedStartupFile)
            renamedStartupFile = nil
        end
        return
    end
    originalFS.delete(path)
end

-- Override the open method
function HiddenFS.open(path, mode)
    if path == "startup.lua" then
        if renamedStartupFile then
            return originalFS.open(renamedStartupFile, mode)
        end
        return nil
    end
    return originalFS.open(path, mode)
end

-- Override the find method
function HiddenFS.find(path, showHidden)
    local items = originalFS.find(path)
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
function HiddenFS.isDir(path)
    return originalFS.isDir(path)
end

function HiddenFS.getSize(path)
    return originalFS.getSize(path)
end

function HiddenFS.makeDir(path)
    return originalFS.makeDir(path)
end

function HiddenFS.getDir(path)
    return originalFS.getDir(path)
end

function HiddenFS.getName(path)
    return originalFS.getName(path)
end

function HiddenFS.getDrive(path)
    return originalFS.getDrive(path)
end

function HiddenFS.combine(base, append)
    return originalFS.combine(base, append)
end

function HiddenFS.attributes(path)
    return originalFS.attributes(path)
end

function HiddenFS.complete(partial, path, includeFiles, includeDirs)
    local results = originalFS.complete(partial, path, includeFiles, includeDirs)
    local filteredResults = {}
    for _, result in ipairs(results) do
        local isHidden = false
        for hidden in pairs(hiddenDirs) do
            if string.sub(result, 1, #hidden) == hidden then
                isHidden = true
                break
            end
        end
        if not isHidden then
            table.insert(filteredResults, result)
        end
    end
    return filteredResults
end

-- Metatable to handle the "nil-like" behavior for custom functions
setmetatable(HiddenFS, {
    __index = function(_, key)
        local validCustomMethods = {
            hide = true,
            unhide = true,
            isHidden = true,
            setRenamedStartup = true,
            enable = true,
            disable = true,
        }
        if validCustomMethods[key] then
            return function(...)
                return HiddenFS[key](...)
            end
        end
        return originalFS[key] -- Pass-through to original FS
    end,

    __newindex = function(_, key, value)
        error("Attempt to modify read-only table: " .. tostring(key))
    end,
})

return HiddenFS
