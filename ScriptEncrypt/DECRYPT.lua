-- Global DECRYPT table to hold decryption functions and utilities
DECRYPT = {}

-- XOR Decrypt function
function DECRYPT.xor_decrypt(input, key)
    local output = {}
    for i = 1, #input do
        local key_char = key:byte((i - 1) % #key + 1)
        local input_char = input:byte(i)
        output[i] = string.char(bit32.bxor(input_char, key_char))
    end
    return table.concat(output)
end

-- Base64 Decode function
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' -- Base64 character set

function DECRYPT.base64_decode(data)
    data = string.gsub(data, '[^' .. b .. '=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i - 1) > 0 and '1' or '0') end
        return r
    end):gsub('%d%d%d%d%d%d%d%d', function(x)
        return string.char(tonumber(x, 2))
    end))
end

-- Function to decrypt and load the Lua script
function DECRYPT.load_script(encrypted_base64_script, key)
    local encrypted_script = DECRYPT.base64_decode(encrypted_base64_script)  -- Decode Base64
    local decrypted_script = DECRYPT.xor_decrypt(encrypted_script, key)  -- Decrypt using XOR

    -- Load and execute the decrypted script
    local func, err = load(decrypted_script)
    if func then
        func()  -- Executes the Lua script
    else
        print("Error in execution: ", err)
    end
end
