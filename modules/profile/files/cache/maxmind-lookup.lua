-- SPDX-License-Identifier: MIT
-- This file is managed by puppet
local maxminddb = require("maxminddb")

local isp_dbpath = "/usr/share/GeoIP/GeoIP2-ISP.mmdb"
local datacenter_dbpath = "/usr/share/GeoIP/datacenter.mmdb"
local proxy_dbpath = "/usr/share/GeoIP/proxy.mmdb"

local error_response = ""
local isp_db, err = maxminddb.open(isp_dbpath)
local datacenter_db, dc_err = maxminddb.open(datacenter_dbpath)
local proxy_db, proxy_db_err = maxminddb.open(proxy_dbpath)

if not isp_db then
    core.Alert("Error opening MaxMind ISP DB: " .. err)
    return
end

if not datacenter_db then
   core.Warning("Error opening Datacenter DB:" .. dc_err)
end

if not proxy_db then
   core.Warning("Error opening Proxy DB:" .. proxy_db_err)
end


function fetch_isp(txn)
   local ip_address = txn.f:src()
   local ok, result, status = pcall(isp_db.lookup, isp_db, ip_address)
   if not ok then
      return error_response
   end

   local ok, isp = pcall(result.get, result, "isp")
   if not ok or isp == nil or isp == '' then
      return error_response
   end

   return 'isp=' .. isp:gsub(";", ",")
end

function is_datacenter(txn)
   if not datacenter_db then
      return
   end

   local ip_address = txn.f:src()
   local ok, result, status = pcall(datacenter_db.lookup, datacenter_db, ip_address)
   if not ok then
      return
   end
   local ok, org = pcall(result.get, result, "autonomous_system_organization")
   if ok and org then
      txn:set_var('txn.is_datacenter', true)
   end
end

function is_res_proxy(txn)
   if not proxy_db then
      return
   end

   local ip_address = txn.f:src()
   local ok, result, status = pcall(proxy_db.lookup, proxy_db, ip_address)
   if not ok then
      return
   end
   local ok, org = pcall(result.get, result, "callbackProxy")
   if ok and org then
      txn:set_var('txn.res_proxy', "proxy=" .. org:gsub("_PROXY", ""):lower())
   end
end

core.register_fetches("fetch_isp", fetch_isp)
core.register_action('is_datacenter', {'http-req'}, is_datacenter)
core.register_action('res_proxy', {'http-req'}, is_res_proxy)
