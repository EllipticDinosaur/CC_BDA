-- SPDX-FileCopyrightText: 2024 David Lightman
--
-- SPDX-License-Identifier: LicenseRef-CCPL
local utils = {}
utils.__index = utils


function utils.generateRandomString(length)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    for i = 1, length do
        local rand = math.random(1, #charset)
        table.insert(result, charset:sub(rand, rand))
    end
    return table.concat(result)
end


-- Base64 character set
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local b64lookup = {}
for i = 1, #b64chars do
    b64lookup[b64chars:sub(i, i)] = i - 1
end

-- Base64 encode
function utils.base64Encode(input)
    local output = {}
    for i = 1, #input, 3 do
        local a, b, c = input:byte(i, i + 2)
        local n = (a or 0) * 0x10000 + (b or 0) * 0x100 + (c or 0)
        for j = 1, 4 do
            local digit = (n / (2 ^ (6 * (4 - j)))) % 64 + 1
            table.insert(output, b64chars:sub(digit, digit))
        end
    end
    if #input % 3 == 1 then
        output[#output - 1] = '='
        output[#output] = '='
    elseif #input % 3 == 2 then
        output[#output] = '='
    end
    return table.concat(output)
end

-- Base64 decode
function utils.base64Decode(input)
    input = input:gsub("=", "")
    local output = {}
    for i = 1, #input, 4 do
        local n = 0
        for j = 1, 4 do
            local char = input:sub(i + j - 1, i + j - 1)
            n = n * 64 + (b64lookup[char] or 0)
        end
        table.insert(output, string.char((n > 16) and 0xFF, (n > 8) and 0xFF, n and 0xFF))
    end
    return table.concat(output)
end

function utils.jsonEncode(tbl)
    local items = {}
    for k, v in pairs(tbl) do
        local key = tostring(k):gsub('"', '\\"')
        local value = tostring(v):gsub('"', '\\"')
        table.insert(items, '"' .. key .. '":"' .. value .. '"')
    end
    return "{" .. table.concat(items, ",") .. "}"
end

function utils.jsonDecode(str)
    local tbl = {}
    for key, value in str:gmatch('"(.-)":"(.-)"') do
        tbl[key] = value
    end
    return tbl
end

function utils.getMetadataValue(fs1, file, key, separator)
    local meta = utils.getMetadata(fs1, file, separator)
    if not meta then return nil, "No metadata found" end

    return meta[key], nil
end


function utils.addMetadata(fs1, file, key, value, separator)
    local meta = utils.getMetadata(fs1, file, separator) or {}
    meta[key] = value
    saveMetadata(fs1, file, meta, separator)
end

function utils.removeMetadata(fs1, file, key, separator)
    local meta = utils.getMetadata(fs1, file, separator) or {}
    meta[key] = nil
    saveMetadata(fs1, file, meta, separator)
end

function utils.getMetadata(fs1, file, separator)
    if (file==nil) then print("file is nil") end
    local path = file
    if not fs1.exists(path) then return nil end

    local f = fs1.open(path, "r")
    if not f then return nil end

    while true do
        local line = f.readLine()
        if not line then break end
        local meta = line:match("^%-%-" .. separator .. "(.+)" .. separator .. "$")
        if meta then
            local decoded = base64Decode(meta)
            f.close()
            return jsonDecode(decoded)
        end
    end
    f.close()
    return nil
end
local function saveMetadata(fs1, file, meta, separator)
    local path = file
    if not fs1.exists(path) then return end

    local f = fs1.open(path, "r")
    if not f then return end

    local lines = {}
    while true do
        local line = f.readLine()
        if not line then break end
        if not line:match("^%-%-" .. separator) then
            table.insert(lines, line)
        end
    end
    f.close()

    local encoded = base64Encode(jsonEncode(meta))
    table.insert(lines, 1, "--" .. separator .. encoded .. separator)

    f = fs1.open(path, "w")
    for _, line in ipairs(lines) do
        f.write(line .. "\n")
    end
    f.close()
end


function utils.getFileSize(fs1, filePath)
    if not fs1.exists(filePath) or fs1.isDir(filePath) then
        return nil, "File does not exist or is a directory"
    end

    local file = fs1.open(filePath, "r")
    if not file then
        return nil, "Failed to open file"
    end

    size = #file.readAll()
    file.close()
    return size
end

function utils.getDirectorySize(fs1, dirPath)
    if not fs1.exists(dirPath) or not fs1.isDir(dirPath) then
        return nil, "Directory does not exist or is not a directory"
    end

    local totalSize = 0

    local function calculateSize(path)
        if fs1.isDir(path) then
            local items = fs1.list(path)
            for _, item in ipairs(items) do
                calculateSize(fs1.combine(path, item))
            end
        else
            local file = fs1.open(path, "r")
            if file then
                totalSize = totalSize + #file.readAll()
                file.close()
            end
        end
    end

    calculateSize(dirPath)
    return totalSize
end

return utils