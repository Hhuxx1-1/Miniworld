-- Global DECRYPT table to hold decryption functions and utilities
DECRYPT = {}

-- Custom function to perform bitwise XOR
function DECRYPT.bxor(a, b)
    local result = 0
    local shift = 1
    while a > 0 or b > 0 do
        local bit_a = a % 2
        local bit_b = b % 2
        
        -- Calculate XOR bit manually
        local xor_bit = (bit_a + bit_b) % 2 -- XOR operation: 1 if bits are different, 0 if same
        result = result + xor_bit * shift
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        shift = shift * 2
    end
    return result
end

-- XOR Decrypt function using the custom bxor function
function DECRYPT.xor_decrypt(input, key)
    local output = {}
    for i = 1, #input do
        local key_char = key:byte((i - 1) % #key + 1)
        local input_char = input:byte(i)
        output[i] = string.char(DECRYPT.bxor(input_char, key_char)) -- Use custom bxor function
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
    if load then 
        local func, err = load(decrypted_script)

        if func then
            func()  -- Executes the Lua script
        else
            print("Error in execution Load : ", err)
        end
    else 
        local func, err = LoadLuaScript(decrypted_script)

        if func then
            func()  -- Executes the Lua script
        else
            print("Error in execution Loadstring: ", err)
        end
    end 
end

-- Example usage:
-- local encrypted_base64_script = "HQs2HRFLUA0RMwcKWToWLR8BEFBMT1UbFxADDXdRDQYeCRt/PAoLAR1tUUxY"  -- Replace with your Base64 encoded encrypted script
-- local encryption_key = "my_secret_key"  -- The same key used in encryption

-- -- Load and execute the encrypted script
-- DECRYPT.load_script(encrypted_base64_script, encryption_key)
