-- SPDX-License-Identifier: MIT
-- Copyright (C) 2025 Chris Danis & Wikimedia Foundation
-- modified from: https://github.com/O-X-L/haproxy-ja4h-fingerprint
-- Copyright (C) 2024 Rath Pascal
-- License: MIT
-- Algorithm License: FoxIO License (https://github.com/FoxIO-LLC/ja4/blob/main/LICENSE)


-- Implements a modified version of the JA4H fingerprinting algorithm
-- specialized for Wikimedia use cases.
--
-- see: https://github.com/FoxIO-LLC/ja4
-- use in haproxy:
--   register: lua-load /etc/haproxy/lua/ja4h.lua (in global)
--   run: http-request lua.fingerprint_ja4h
--   log: http-request capture var(txn.fingerprint_ja4h) len 38
--   acl: var(txn.fingerprint_ja4h) -m str ge11cr05enus_75583abecd62_d02f42d4a372


local function http_version(txn)
    local v = txn.f:req_ver()
    if (v == '3.0') then
        return '30'
    elseif (v == '2.0') then
        return '20'
    else
        return '11'
    end
end

local function method_code(txn)
    return string.lower(string.sub(txn.f:method(), 1, 2))
end

local function referer_is_set(txn)
    local r = txn.f:req_fhdr('referer')
    if (not r) then
        return 'n'
    end
    return 'r'
end

local function cookie_is_set(txn)
    local c = txn.f:req_fhdr('cookie')
    if (not c) then
        return 'n'
    end
    return 'c'
end

-- https://github.com/FoxIO-LLC/ja4/blob/main/python/ja4h.py#L12
local function accept_lang_beg(txn)
    local al = txn.f:req_fhdr('accept-language')
    if (not al) then
        return '0000'
    end
    al = al:gsub('%W','')
    return string.rep('0', 4 - #al) .. string.lower(string.sub(al, 1, 4))
end

local function split_string(str, delimiter)
    local delimiter = delimiter or ','
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from, true)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from-1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from, true)
    end
    table.insert(result, string.sub(str, from))
    return result
end

local function truncated_sha256(txn, value)
    if (not value or #value == 0) then
        return '000000000000'
    else
        return string.lower(string.sub(txn.c:hex(txn.c:digest(value, 'sha256')), 1, 12))
    end
end

-- Don't count cookie or referer headers, max 99, stringified with leading zero
local function count_headers(txn, header_names)
    local count = 0
    for _, h in ipairs(header_names) do
        if (h ~= 'cookie' and h ~= 'referer') then
            count = count + 1
        end
        if (count >= 99) then
            break
        end
    end
    return string.format('%02d', count)
end


-- called from haproxy as `http-request lua.fingerprint_ja4h`
-- sets variables `txn.fingerprint_ja4h`,
--                `txn.fingerprint_ja4h_hdrs`,
--                `txn.fingerprint_ja4h_hdrs_ordered`
function fingerprint_ja4h(txn)
    local method = method_code(txn)
    local ver = http_version(txn)

    local hdrs_str = txn.f:req_hdr_names()
    local header_names = split_string(hdrs_str)
    table.sort(header_names)

    local header_count = count_headers(txn, header_names)

    local rv = core.concat()

    local sorted_hdrs_hash = truncated_sha256(txn, table.concat(header_names, ','))
    local ordered_hdrs_hash = truncated_sha256(txn, hdrs_str)

    rv:add(method)
    rv:add(ver)
    rv:add(cookie_is_set(txn))
    rv:add(referer_is_set(txn))
    rv:add(header_count)
    rv:add(accept_lang_beg(txn))
    rv:add("_")
    rv:add(sorted_hdrs_hash)
    rv:add("_")
    rv:add(ordered_hdrs_hash)

    local fprint = rv:dump()
    txn:set_var('txn.fingerprint_ja4h', fprint)
    txn:set_var('txn.fingerprint_ja4h_hdrs', sorted_hdrs_hash)
    txn:set_var('txn.fingerprint_ja4h_hdrs_ordered', ordered_hdrs_hash)
end

core.register_action('fingerprint_ja4h', {'http-req'}, fingerprint_ja4h)
