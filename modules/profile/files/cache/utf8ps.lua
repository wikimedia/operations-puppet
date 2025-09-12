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
            if not is_printable(codepoint) then
                if codepoint <= 0xffff then
                    str = string.format("\\u%04x", codepoint)
                 else
                    str = string.format("\\U%08x", codepoint)
                 end
            else
                -- Get the actual UTF-8 character
                local next_pos = utf8.offset(payload, 2, pos) or (len + 1)
                str = string.sub(payload, pos, next_pos -1)
            end
            table.insert(result, str)
            pos = utf8.offset(payload, 2, pos) or (len + 1)

        end
    end

    return table.concat(result)
end

core.register_converters("utf8ps", utf8ps)
