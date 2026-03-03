-- SPDX-License-Identifier: MIT
-- Source: https://github.com/O-X-L/haproxy-ja3n
-- Copyright (C) 2024 Rath Pascal
-- License: MIT
-- Algorithm License: BSD 3-Clause

-- JA3N = sorted extensions to tackle browsers randomizing their order
-- see: https://github.com/salesforce/ja3/issues/88
-- examples:
--   before (JA3): 51-27-0-16-17513-65281-23-65037-11-45-43-5-35-10-18-13
--   after (JA3N): 0-5-10-11-13-16-18-23-27-35-43-45-51-17513-65037-65281
-- usage:
--   register: lua-load /etc/haproxy/lua/ja3n.lua (in global)
--   run: http-request lua.fingerprint_ja3n
--   log: http-request capture var(sess.fingerprint_ja3n) len 32
--   acl: var(sess.fingerprint_ja3n) -m str a195b9c006fcb23ab9a2343b0871e362

local function split_string(str, delimiter)
    local result = {}
    local from  = 1
    local delim_from, delim_to = string.find(str, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(str, from , delim_from-1))
        from  = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

local function sortNumbers(a, b)
    if (a == nil or b == nil)
    then
        return false
    end

    return tonumber(a) < tonumber(b)
end

function fingerprint_ja3n(txn)
    local p1 = tostring(txn.f:ssl_fc_protocol_hello_id())
    local p2 = tostring(txn.c:be2dec(txn.f:ssl_fc_cipherlist_bin(1), '-', 2))

    local p3u = tostring(txn.c:be2dec(txn.f:ssl_fc_extlist_bin(1), '-', 2))
    local p3l = split_string(p3u, '-')
    table.sort(p3l, sortNumbers)
    local p3 = table.concat(p3l, '-')

    local p4 = tostring(txn.c:be2dec(txn.f:ssl_fc_eclist_bin(1),'-',2))
    local p5 = tostring(txn.c:be2dec(txn.f:ssl_fc_ecformats_bin(),'-',1))

    local c = core.concat()
    c:add(p1)
    c:add(',')
    c:add(p2)
    c:add(',')
    c:add(p3)
    c:add(',')
    c:add(p4)
    c:add(',')
    c:add(p5)
    local fingerprint = c:dump()
    local fingerprint_hash = string.lower(txn.c:hex(txn.c:digest(fingerprint, 'md5')))

--    txn:set_var('sess.fingerprint_ja3n_raw', fingerprint)
    txn:set_var('sess.fingerprint_ja3n', fingerprint_hash)
end

core.register_action('fingerprint_ja3n', {'http-req'}, fingerprint_ja3n)
