-- Bloom filter lookup action for HAProxy
-- This module is part of the CIDERGRINDER project: https://gitlab.wikimedia.org/repos/sre/CIDERGRINDER
-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (C) 2026 Chris Danis & the Wikimedia Foundation

local Bloom = require("bloom")  -- our C library

-- Global bloom filter instance
local bloom_filter = nil
local expected_payload_hash = nil

local args = table.pack(...)

core.register_init(function()
    if #args < 1 then
        core.Alert("Bloom filter file name not provided")
        return
    end

    local fname = args[1]
    local file = io.open(fname, "rb")  -- file io allowed in init context
    if not file then
        core.Alert("Failed to open bloom filter file: " .. fname)
        return
    end

    -- Parse the headers, make note of the checksum
    -- Example file contents:
    -- PUT /spur.bloom CIDERBLOOM/0.1\r\n
    -- Bits: 1234567\r\n
    -- Hashes: 13\r\n
    -- Payload-Xxhash3: abcdef1234567890\r\n
    -- Other-user-defined-metadata: value\r\n
    -- \r\n[binary data begins]

    -- check the header line, should contain "CIDERBLOOM/0.1"
    local header = file:read("*l")
    if not header or not header:match("CIDERBLOOM/0%.1") then
        core.Alert("Invalid bloom filter file header: " .. tostring(header))
        file:close()
        return
    end

    local hdrs = {}
    -- parse key: value lines until we hit an empty line
    -- (keys will never contain whitespace or colons)
    while true do
        local line = file:read("*l")
        if not line or line == "" or line == "\r" then
            break
        end
        local key, value = line:match("^(.-):%s*(.-)%s*$")
        if key and value then
            key = key:lower()
            hdrs[key] = value
        end
    end

    if not hdrs["bits"] or not hdrs["hashes"] then
        core.Alert("Unable to load Bloom filter -- missing required metadata")
        file:close()
        return
    end

    if hdrs["payload-xxhash3"] then
        local hash = tonumber(hdrs["payload-xxhash3"], 16)
        expected_payload_hash = hash
    end

-- TODO: we could take an expected granularity as an arg from the config file and
--       crosscheck that against the x-granularity header.

    local bits = tonumber(hdrs["bits"])
    local hashes = tonumber(hdrs["hashes"])
    if not bits or not hashes then
        core.Alert("Invalid bloom filter header values")
        file:close()
        return
    end

    core.Debug("File payload offset: " .. file:seek("cur", 0))

    local ok, bf_or_err = pcall(Bloom.open, file, bits, hashes)
    -- Safe to close the file on error or success; mmap() has our back.
    file:close()
    if not ok then
        core.Alert("Failed to initialize bloom filter from file: " .. fname .. " (" .. tostring(bf_or_err) .. ")")
        bloom_filter = nil
        return
    end
    bloom_filter = bf_or_err

    if expected_payload_hash then
        local hash = bloom_filter:checksum()
        if hash ~= expected_payload_hash then
            core.Alert(string.format("Unloading the Bloom filter! checksum mismatch: expected %016x, got %016x", expected_payload_hash, hash))
            bloom_filter = nil
        else
            core.Debug(string.format("Bloom filter checksum matches expected value: %016x", hash))
        end
    else
        core.Warning("Bloom filter metadata lacks payload-xxhash3; skipping integrity check")
    end

    core.Info(string.format("Bloom filter %s loaded OK! parameters: bits=%d, hashes=%d", fname, bits, hashes))
end)

-- `http-request lua.bloom_lookup`
-- expects var(sess.prehashed) to be set to a hash value to check against the bloom filter
-- sets var(sess.bloom_result) to true or false based on the lookup
core.register_action("bloom_lookup", { "http-req", "tcp-req" }, function(txn)
    if not bloom_filter then
        return
    end

    local h = txn:get_var("sess.prehashed")
    if h then
        local r = bloom_filter:contains_hashval(h)
        txn:set_var("sess.bloom_result", r)
    end
end)

core.Info("Bloom filter action registered")
