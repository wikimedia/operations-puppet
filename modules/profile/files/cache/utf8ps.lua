-- SPDX-License-Identifier: Apache-2.0
-- Lua port of the utf8ps decoder embedded in HAProxy json() converter
-- https://github.com/haproxy/haproxy/blob/6cf2401edaf80806828526d214d1a9d5e25ba5d9/src/sample.c#L2687

local utf8 = require "utf8"
-- isprint() port
function is_printable(c)
    if c >= 32 and c <= 126 then
        return true
    end

    -- basic multilingual blocks
    if c >= 0xa0 and c <= 0xd7ff then
        return true
    end

    -- private use and other alphabet
    if c >= 0xe000 and c <= 0xfdcf then
        return true
    end

    return false
end

-- function to determine the byte length of a UTF-8 character
function utf8_char_length(s, pos)
    local byte = string.byte(s, pos)
    if byte < 128 then
        return 1
    elseif byte < 224 then
        return 2
    elseif byte < 240 then
        return 3
    elseif byte < 248 then
        return 4
    else
        return 1  -- Invalid, treat as single byte
    end
end

function utf8ps(payload)
    local result = {}
    local pos = 1
    local len = #payload

    while pos <= len do
        local success, codepoint = pcall(utf8.codepoint, payload, pos)
        if not success then
            -- Invalid UTF-8 sequence, process as raw byte
            local c = string.byte(payload, pos)
            table.insert(result, string.format("\\u%04x", c))
            pos = pos + 1
        else
            local str
            local char_len = utf8_char_length(payload, pos)
            if not is_printable(codepoint) then
                if codepoint <= 0xffff then
                    str = string.format("\\u%04x", codepoint)
                 else
                    str = string.format("\\U%08x", codepoint)
                 end
            else
                -- Get the actual UTF-8 character
                str = string.sub(payload, pos, pos + char_len -1)
            end
            table.insert(result, str)
            pos = pos + char_len
        end
    end

    return table.concat(result)
end

core.register_converters("utf8ps", utf8ps)
