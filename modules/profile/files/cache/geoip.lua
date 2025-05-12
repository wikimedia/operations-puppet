-- SPDX-License-Identifier: MIT
-- This file is managed by puppet

-- maxminddb.so must be in the LUA path or in the same directory
-- as the present script
local maxminddb = require("maxminddb")
local dbpath = "/usr/share/GeoIP/GeoIP2-ISP.mmdb"
local db, err = maxminddb.open(dbpath)
if not db then
    core.Alert("Error opening MaxMind DB: " .. err)
    return
end

local function lookup_geoip(txn)
   local ip_address = txn.f:src()
   local result, err = db:lookup(ip_address)

   if not result then
      core.Alert("Error looking up IP: " .. err)
      txn.set_var(txn, "req.isp", "N/A")
      return
   end

   local isp = result:get("isp") or "N/A"
   txn.set_var(txn, "req.isp", isp)
end

core.register_action("lookup_geoip", {"tcp-req", "http-req"}, lookup_geoip)
