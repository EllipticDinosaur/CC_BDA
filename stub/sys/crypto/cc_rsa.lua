-- Helper functions for modular exponentiation
local function modExp(base, exp, mod)
    local result = 1
    base = base % mod
    while exp > 0 do
        if exp % 2 == 1 then
            result = (result * base) % mod
        end
        exp = math.floor(exp / 2)
        base = (base * base) % mod
    end
    return result
end

-- Helper function to generate random prime numbers
local function isPrime(num)
    if num < 2 then return false end
    for i = 2, math.sqrt(num) do
        if num % i == 0 then return false end
    end
    return true
end

local function generateRandomPrime()
    while true do
        local candidate = math.random(50, 100)
        if isPrime(candidate) then
            return candidate
        end
    end
end

-- RSA functions
local rsa = {}

function rsa.generateKeys()
    local p, q = generateRandomPrime(), generateRandomPrime()
    while p == q do
        q = generateRandomPrime()
    end
    local n = p * q
    local phi = (p - 1) * (q - 1)
    local e = 17 -- Public exponent (must be coprime with phi and 1 < e < phi)

    -- Calculate d (private exponent)
    local d = 0
    for k = 1, phi do
        if ((k * phi + 1) % e == 0) then
            d = (k * phi + 1) / e
            break
        end
    end

    return {public = {e = e, n = n}, private = {d = d, n = n}}
end

function rsa.loadPublicKey(keyString)
    local e, n = keyString:match("(%d+),(%d+)")
    if not e or not n then
        error("Invalid public key format. Expected 'e,n'")
    end
    return {e = tonumber(e), n = tonumber(n)}
end

function rsa.loadPrivateKey(keyString)
    local d, n = keyString:match("(%d+),(%d+)")
    if not d or not n then
        error("Invalid private key format. Expected 'd,n'")
    end
    return {d = tonumber(d), n = tonumber(n)}
end

function rsa.encrypt(publicKey, message)
    local encrypted = {}
    for i = 1, #message do
        local char = message:byte(i)
        table.insert(encrypted, modExp(char, publicKey.e, publicKey.n))
    end
    return toBase64(table.concat(encrypted, ","))
end

function rsa.decrypt(privateKey, base64Cipher)
    local cipher = fromBase64(base64Cipher)
    local decrypted = {}
    for num in cipher:gmatch("(%d+)") do
        local char = modExp(tonumber(num), privateKey.d, privateKey.n)
        table.insert(decrypted, string.char(char))
    end
    return table.concat(decrypted)
end

-- Helper functions for Base64 encoding and decoding
local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function toBase64(data)
    return ((data:gsub(".", function(x)
        local r, b = "", x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
        if (#x < 6) then return "" end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0) end
        return b:sub(c + 1, c + 1)
    end) .. ({ "", "==", "=" })[#data % 3 + 1])
end

function fromBase64(data)
    data = data:gsub("[^" .. b .. "=]", "")
    return (data:gsub(".", function(x)
        if (x == "=") then return "" end
        local r, f = "", (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d%d%d%d%d%d", function(x)
        if (#x ~= 8) then return "" end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

-- Example usage
local keys = rsa.generateKeys()
local publicKeyString = keys.public.e .. "," .. keys.public.n
local privateKeyString = keys.private.d .. "," .. keys.private.n

print("Public Key: " .. publicKeyString)
print("Private Key: " .. privateKeyString)

local publicKey = rsa.loadPublicKey(publicKeyString)
local privateKey = rsa.loadPrivateKey(privateKeyString)

local message = "Hello, RSA!"
print("Original Message: " .. message)

local encrypted = rsa.encrypt(publicKey, message)
print("Encrypted (Base64): " .. encrypted)

local decrypted = rsa.decrypt(privateKey, encrypted)
print("Decrypted Message: " .. decrypted)
