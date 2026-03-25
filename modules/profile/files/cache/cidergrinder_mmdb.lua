-- MMDB file lookup action for HAProxy
-- This module is part of the CIDERGRINDER project: https://gitlab.wikimedia.org/repos/sre/CIDERGRINDER
-- SPDX-License-Identifier: GPL-3.0-or-later
-- Copyright (C) 2026 Chris Danis & the Wikimedia Foundation

local maxminddb = require("maxminddb")

local args = table.pack(...)

local cider_mmdb = nil

-- lua-load-per-thread mmdb_action.lua /path/to/file.mmdb
core.register_init(function()
    if #args < 1 then
        core.Alert("MMDB file name not provided")
        return
    end

    local fname = args[1]
    local err
    cider_mmdb, err = maxminddb.open(fname)
    if not cider_mmdb then
        core.Alert("Failed to load MMDB file: " .. tostring(err))
        return
    end

    core.Log("Successfully loaded MMDB file: " .. fname)
end)

-- http-request lua.cidergrinder_mmdb_lookup
-- Sets the variable "sess.cidergrinder_mmdb_result" to the value of the
-- "proxy" field in the MMDB record for the client IP, if it exists.
-- Otherwise leaves it unset.
core.register_action("cidergrinder_mmdb_lookup", { "http-req", "tcp-req" }, function(txn)
    if not cider_mmdb then
        return
    end

    local ip = txn.f:src()
    local ok, result, status = pcall(cider_mmdb.lookup, cider_mmdb, ip)
    if not ok then
        return
    end

    local ok, result = pcall(cider_mmdb.get, result, "proxy")
    if ok and result then
        txn:set_var("sess.cidergrinder_mmdb_result", result)
    end
end)
