local HiddenFS = {}
local hiddenDirs = {}
local renamedStartupFile = nil -- To store the renamed startup file name

-- Backup the original fs
HiddenFS.originalFS = _G.fs

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
end

-- Disable the custom fs API and restore the original
function HiddenFS.disable()
    _G.fs = HiddenFS.originalFS
end

-- Override the list method
function HiddenFS.list(path, showHidden)
    local items = HiddenFS.originalFS.list(path)
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
            return HiddenFS.originalFS.exists(renamedStartupFile)
        end
        return false
    end
    for hidden in pairs(hiddenDirs) do
        if path == hidden or string.sub(path, 1, #hidden + 1) == hidden .. "/" then
            return false
        end
    end
    return HiddenFS.originalFS.exists(path)
end

-- Override the delete method
function HiddenFS.delete(path)
    if path == "startup.lua" then
        if renamedStartupFile then
            HiddenFS.originalFS.delete(renamedStartupFile)
            renamedStartupFile = nil
        end
        return
    end
    HiddenFS.originalFS.delete(path)
end

-- Override the open method
function HiddenFS.open(path, mode)
    if path == "startup.lua" then
        if renamedStartupFile then
            return HiddenFS.originalFS.open(renamedStartupFile, mode)
        end
        return nil
    end
    return HiddenFS.originalFS.open(path, mode)
end

-- Override the find method
function HiddenFS.find(path, showHidden)
    local items = HiddenFS.originalFS.find(path)
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
    return HiddenFS.originalFS.isDir(path)
end

function HiddenFS.getSize(path)
    return HiddenFS.originalFS.getSize(path)
end

function HiddenFS.makeDir(path)
    return HiddenFS.originalFS.makeDir(path)
end

function HiddenFS.getDir(path)
    return HiddenFS.originalFS.getDir(path)
end

function HiddenFS.getName(path)
    return HiddenFS.originalFS.getName(path)
end

function HiddenFS.getDrive(path)
    return HiddenFS.originalFS.getDrive(path)
end

function HiddenFS.combine(base, append)
    return HiddenFS.originalFS.combine(base, append)
end

function HiddenFS.getCapacity(path)
    return HiddenFS.originalFS.getCapacity(path)
end

function HiddenFS.attributes(path)
    return HiddenFS.originalFS.attributes(path)
end

function HiddenFS.complete(partial, path, includeFiles, includeDirs)
    local results = HiddenFS.originalFS.complete(partial, path, includeFiles, includeDirs)
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
            return setmetatable({}, {
                __call = function(_, ...) return HiddenFS[key](...) end,
                __tostring = function() return "nil" end,
                __metatable = nil
            })
        end
        return nil
    end,

    __newindex = function(_, key, value)
        error("Attempt to modify read-only table: " .. tostring(key))
    end,
})

return HiddenFS
