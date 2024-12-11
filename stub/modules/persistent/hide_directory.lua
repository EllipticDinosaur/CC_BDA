-- HiddenFS API
local HiddenFS = {}
local hiddenDirs = {}

-- Backup the original fs
HiddenFS.originalFS = fs

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

-- Override the list method
function HiddenFS.list(path)
    local items = HiddenFS.originalFS.list(path)
    local filteredItems = {}
    for _, item in ipairs(items) do
        if not hiddenDirs[item] then
            table.insert(filteredItems, item)
        end
    end
    return filteredItems
end

-- Override the exists method
function HiddenFS.exists(path)
    for hidden in pairs(hiddenDirs) do
        if path == hidden or string.sub(path, 1, #hidden + 1) == hidden .. "/" then
            return false
        end
    end
    return HiddenFS.originalFS.exists(path)
end

-- Override the find method
function HiddenFS.find(path)
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
        if not isHidden then
            table.insert(filteredItems, item)
        end
    end
    return filteredItems
end

-- Pass-through for other methods
function HiddenFS.open(path, mode)
    return HiddenFS.originalFS.open(path, mode)
end

function HiddenFS.isDir(path)
    return HiddenFS.originalFS.isDir(path)
end

function HiddenFS.getSize(path)
    return HiddenFS.originalFS.getSize(path)
end

function HiddenFS.delete(path)
    return HiddenFS.originalFS.delete(path)
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

-- Enable the custom fs API globally
function HiddenFS.enable()
    _G.fs = HiddenFS
end

-- Disable the custom fs API and restore the original
function HiddenFS.disable()
    _G.fs = HiddenFS.originalFS
end

return HiddenFS
