-- SPDX-License-Identifier: MIT
-- This file is managed by puppet
local maxminddb = require("maxminddb")

local isp_dbpath = "/usr/share/GeoIP/GeoIP2-ISP.mmdb"
local error_response = "N/A"
local isp_db, err = maxminddb.open(isp_dbpath)
if not isp_db then
    core.Alert("Error opening MaxMind ISP DB: " .. err)
    return
end

core.register_fetches("fetch_isp", fetch_isp)

function fetch_isp(txn)
   local ip_address = txn.f:src()
   local ok, result, status = pcall(isp_db.lookup, isp_db, ip_address)
   if not ok then
      -- core.Alert("Error looking up IP " .. ip_address)
      return error_response
   end

   local ok, isp = pcall(result.get, result, "isp")
   if not ok then
      return error_response
   end

   return isp
end
