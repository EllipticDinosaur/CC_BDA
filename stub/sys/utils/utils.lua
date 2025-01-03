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
            local digit = (n // (2 ^ (6 * (4 - j)))) % 64 + 1
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
        table.insert(output, string.char((n >> 16) & 0xFF, (n >> 8) & 0xFF, n & 0xFF))
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

function utils.addMetadata(fs1, file, key, value, separator)
    local meta = getMetadata(separator) or {}
    meta[key] = value
    saveMetadata(fs1, file, meta, separator)
end

function utils.removeMetadata(fs1, file, key, separator)
    local meta = getMetadata(separator) or {}
    meta[key] = nil
    saveMetadata(fs1, file, meta, separator)
end

function utils.getMetadata(fs1, file, separator)
    local path = file
    if not path then return nil end
    local f = fs1.open(path, "r")
    if not f then return nil end

    for line in f.readLine do
        local meta = line:match("^%-%-(.+)$")
        if meta then
            local decoded = base64Decode(meta)
            return jsonDecode(decoded)
        end
    end
    f.close()
    return nil
end

local function saveMetadata(fs1, file, meta, separator)
    local path = file
    if not path then return end
    local f = fs1.open(path, "r")
    if not f then return end

    local lines = {}
    for line in f.readLine do
        if not line:match("^%-%-") then
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

return utils