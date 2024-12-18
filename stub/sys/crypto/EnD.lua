local function xorStrings(input, key)
    local output = {}
    for i = 1, #input do
        local inputChar = input:byte(i)
        local keyChar = key:byte((i - 1) % #key + 1)
        table.insert(output, string.char(bit.bxor(inputChar, keyChar)))
    end
    return table.concat(output)
end

-- Encrypt function
function EnD.encrypt(plaintext, key)
    return xorStrings(plaintext, key)
end

-- Decrypt function (same as encryption due to XOR symmetry)
function EnD.decrypt(ciphertext, key)
    return xorStrings(ciphertext, key)
end